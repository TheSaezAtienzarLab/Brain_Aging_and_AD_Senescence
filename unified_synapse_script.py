#!/usr/bin/env python3
"""
Unified Synapse Downloader and Integrity Checker
- First checks all existing files for corruption
- Removes corrupted files automatically
- Downloads only missing or corrupted files
- Provides comprehensive progress tracking
"""

import pandas as pd
import synapseclient
import os
import sys
import gzip
import hashlib
from pathlib import Path
import re
import time
from datetime import datetime

# Configuration
SYNAPSE_PROJECT_ID = 'syn53254216'
AUTH_TOKEN = "eyJ0eXAiOiJKV1QiLCJraWQiOiJXN05OOldMSlQ6SjVSSzpMN1RMOlQ3TDc6M1ZYNjpKRU9VOjY0NFI6VTNJWDo1S1oyOjdaQ0s6RlBUSCIsImFsZyI6IlJTMjU2In0.eyJhY2Nlc3MiOnsic2NvcGUiOlsidmlldyIsImRvd25sb2FkIl0sIm9pZGNfY2xhaW1zIjp7fX0sInRva2VuX3R5cGUiOiJQRVJTT05BTF9BQ0NFU1NfVE9LRU4iLCJpc3MiOiJodHRwczovL3JlcG8tcHJvZC5wcm9kLnNhZ2ViYXNlLm9yZy9hdXRoL3YxIiwiYXVkIjoiMCIsIm5iZiI6MTc0MjgzODQ4MSwiaWF0IjoxNzQyODM4NDgxLCJqdGkiOiIxODAxNSIsInN1YiI6IjM1MTY3MDUifQ.MSpAyQcQhoLoxzBakFostlmcFetdFQf-wBW8iAaJuWLA3mNK_bYhWzSOGrqZJpM74vn7ICwT8wleP1b7mRuLWoPIuY5VTuSm6KT3DU2ALFkK64yLOHHoP1wKLr4X7Ip34cQrCXkcZ-SPNEKWL1snvJeH1seTvcW0Eyb_Kii8gRGThXP6YopDd8NrJi_venLCX7VDDN8la_hEbWBnSJDSwPRB84v_D1CpszX-UASOZuN-z_DZxym9P21BYABRTSHBQc1H51xWy-1S2zw9TJHW3mx4IzkeRCz4tt2bRjoqM-gcdczQXnCCUW8lkFcqR6dOasxxHHFEzzaRelntFv6SSQ"
TARGET_DIR = "/fs/scratch/PAS2598/senes_raw/CONTROLS"
CSV_FILE = "healthy_controls.csv"

# File integrity thresholds
MIN_FILE_SIZE_MB = 10  # Minimum expected file size in MB
MAX_CORRUPTION_CHECK_MB = 50  # Only check first 50MB of very large files for speed

class SynapseUnifiedDownloader:
    def __init__(self):
        self.syn = None
        self.start_time = time.time()
        self.stats = {
            'existing_intact': 0,
            'existing_corrupted': 0,
            'downloaded_new': 0,
            'downloaded_redownload': 0,
            'failed': 0,
            'total_expected': 0
        }
        
    def log(self, message, level="INFO"):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
    
    def setup_synapse_client(self):
        """Initialize and login to Synapse client"""
        self.log("Logging into Synapse...")
        self.syn = synapseclient.Synapse()
        self.syn.login(authToken=AUTH_TOKEN)
        
        # Verify connection
        user_profile = self.syn.getUserProfile()
        self.log(f"Successfully connected as: {user_profile.userName}")
        return self.syn

    def load_metadata(self, csv_path):
        """Load the healthy controls CSV file"""
        self.log(f"Loading metadata from {csv_path}...")
        if not os.path.exists(csv_path):
            raise FileNotFoundError(f"CSV file not found: {csv_path}")
        
        df = pd.read_csv(csv_path)
        self.log(f"Loaded metadata for {len(df)} individuals")
        return df

    def get_synapse_file_mapping(self, project_id):
        """Create a mapping of filename to Synapse ID and metadata"""
        self.log("Getting Synapse file mapping...")
        
        # Get all files in the project
        children = self.syn.getChildren(project_id, includeTypes=['file'])
        file_mapping = {}
        
        file_count = 0
        for child in children:
            file_mapping[child['name']] = {
                'id': child['id'],
                'name': child['name']
            }
            file_count += 1
            
            # Get additional metadata for the file
            try:
                entity = self.syn.get(child['id'], downloadFile=False)
                if hasattr(entity, 'dataFileHandleId'):
                    file_handle = self.syn._getFileHandle(entity.dataFileHandleId)
                    file_mapping[child['name']]['size'] = file_handle.get('contentSize', 0)
                    file_mapping[child['name']]['md5'] = file_handle.get('contentMd5', None)
            except Exception as e:
                file_mapping[child['name']]['size'] = 0
                file_mapping[child['name']]['md5'] = None
        
        self.log(f"Found {len(file_mapping)} files in Synapse project")
        return file_mapping

    def is_file_corrupted(self, file_path, expected_size=None, expected_md5=None):
        """Check if a file is corrupted or incomplete"""
        if not os.path.exists(file_path):
            return True, "File does not exist"
        
        file_size = os.path.getsize(file_path)
        
        # Check if file is too small (likely incomplete)
        if file_size < MIN_FILE_SIZE_MB * 1024 * 1024:
            return True, f"File too small ({file_size / (1024*1024):.1f} MB < {MIN_FILE_SIZE_MB} MB)"
        
        # Check expected size if available
        if expected_size and expected_size > 0:
            size_diff_percent = abs(file_size - expected_size) / expected_size * 100
            if size_diff_percent > 10:  # Allow 10% variance
                return True, f"Size mismatch: expected {expected_size / (1024*1024):.1f} MB, got {file_size / (1024*1024):.1f} MB"
        
        # Check if it's a valid gzip file (fastq.gz)
        if file_path.endswith('.gz'):
            try:
                with gzip.open(file_path, 'rt') as f:
                    # Try to read first line
                    first_line = f.readline()
                    if not first_line.startswith('@'):  # FASTQ files start with @
                        return True, "Invalid FASTQ format (first line doesn't start with @)"
                    
                    # Try to read a few more lines to check structure
                    for i in range(3):  # Read sequence, +, quality lines
                        line = f.readline()
                        if not line:
                            return True, "Incomplete FASTQ record"
                    
            except Exception as e:
                return True, f"Cannot read gzip file: {str(e)}"
        
        return False, "File appears intact"

    def extract_fastq_columns(self, df):
        """Extract columns that contain fastq filenames"""
        fastq_columns = []
        for col in df.columns:
            # Check first non-null value in the column
            for idx, value in df[col].items():
                if pd.notna(value) and str(value) != '':
                    if 'R1.fastq' in str(value) or 'R2.fastq' in str(value):
                        fastq_columns.append(col)
                    break
        
        self.log(f"Found fastq columns: {fastq_columns}")
        return fastq_columns

    def check_existing_files(self, target_dir):
        """Check all existing files for corruption and remove corrupted ones"""
        self.log("="*60)
        self.log("PHASE 1: CHECKING EXISTING FILES FOR CORRUPTION")
        self.log("="*60)
        
        if not os.path.exists(target_dir):
            self.log("No existing files found (target directory doesn't exist)")
            return
        
        # Find all existing fastq files
        existing_files = []
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if file.endswith('.fastq.gz'):
                    file_path = os.path.join(root, file)
                    existing_files.append(file_path)
        
        if not existing_files:
            self.log("No existing fastq.gz files found")
            return
        
        self.log(f"Found {len(existing_files)} existing fastq.gz files to check")
        
        intact_files = []
        corrupted_files = []
        
        # Check each existing file
        for i, file_path in enumerate(existing_files, 1):
            relative_path = os.path.relpath(file_path, target_dir)
            file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
            
            self.log(f"[{i:3d}/{len(existing_files)}] Checking {relative_path} ({file_size:.1f} MB)...")
            
            is_corrupt, reason = self.is_file_corrupted(file_path)
            
            if is_corrupt:
                self.log(f"    ❌ CORRUPTED - {reason}", "WARN")
                corrupted_files.append((file_path, reason))
                # Remove corrupted file immediately
                try:
                    os.remove(file_path)
                    self.log(f"    🗑️  Removed corrupted file: {relative_path}")
                    self.stats['existing_corrupted'] += 1
                except Exception as e:
                    self.log(f"    ❌ Could not remove corrupted file: {e}", "ERROR")
            else:
                self.log(f"    ✅ OK")
                intact_files.append(file_path)
                self.stats['existing_intact'] += 1
        
        # Summary of corruption check
        self.log(f"\nCorruption check summary:")
        self.log(f"  Intact files: {len(intact_files)}")
        self.log(f"  Corrupted files removed: {len(corrupted_files)}")
        
        if corrupted_files:
            self.log("\nCorrupted files that were removed:")
            for file_path, reason in corrupted_files:
                relative_path = os.path.relpath(file_path, target_dir)
                self.log(f"  - {relative_path}: {reason}")

    def process_individual(self, individual_row, file_mapping, fastq_columns, target_dir):
        """Process all fastq files for a single individual"""
        individual_id = individual_row['individualID']
        individual_dir = os.path.join(target_dir, individual_id)
        
        # Create directory for this individual
        os.makedirs(individual_dir, exist_ok=True)
        
        files_status = {
            'intact': [],
            'downloaded': [],
            'failed': []
        }
        
        for col in fastq_columns:
            fastq_filename = individual_row[col]
            
            # Skip if no filename or NaN
            if pd.isna(fastq_filename) or fastq_filename == '':
                continue
                
            self.stats['total_expected'] += 1
            output_path = os.path.join(individual_dir, fastq_filename)
            
            # Check if file exists and is intact
            if os.path.exists(output_path):
                is_corrupt, reason = self.is_file_corrupted(output_path)
                if not is_corrupt:
                    files_status['intact'].append(fastq_filename)
                    continue
            
            # File is missing or corrupted - need to download
            if fastq_filename in file_mapping:
                synapse_id = file_mapping[fastq_filename]['id']
                expected_size = file_mapping[fastq_filename].get('size', 0)
                
                try:
                    self.log(f"    📥 Downloading {fastq_filename}...")
                    if expected_size > 0:
                        self.log(f"        Expected size: {expected_size / (1024*1024):.1f} MB")
                    
                    start_time = time.time()
                    file_entity = self.syn.get(synapse_id, downloadLocation=individual_dir)
                    download_time = time.time() - start_time
                    
                    # Verify the downloaded file
                    is_corrupt, reason = self.is_file_corrupted(output_path, expected_size)
                    
                    if is_corrupt:
                        self.log(f"        ❌ Downloaded file is corrupted ({reason})", "ERROR")
                        try:
                            os.remove(output_path)
                        except:
                            pass
                        files_status['failed'].append(fastq_filename)
                        self.stats['failed'] += 1
                    else:
                        actual_size = os.path.getsize(output_path)
                        download_speed = actual_size / (1024 * 1024) / max(download_time, 1)  # MB/s
                        self.log(f"        ✅ Success: {actual_size / (1024*1024):.1f} MB, {download_speed:.1f} MB/s")
                        files_status['downloaded'].append(fastq_filename)
                        self.stats['downloaded_new'] += 1
                    
                except Exception as e:
                    self.log(f"        ❌ Download failed: {str(e)}", "ERROR")
                    files_status['failed'].append(fastq_filename)
                    self.stats['failed'] += 1
            else:
                self.log(f"    ❌ File not found in Synapse: {fastq_filename}", "ERROR")
                files_status['failed'].append(fastq_filename)
                self.stats['failed'] += 1
        
        return files_status

    def run_download_phase(self, df, file_mapping, fastq_columns, target_dir):
        """Main download phase"""
        self.log("="*60)
        self.log("PHASE 2: DOWNLOADING MISSING/CORRUPTED FILES")
        self.log("="*60)
        
        # Create target directory
        os.makedirs(target_dir, exist_ok=True)
        
        summary = []
        
        for idx, row in df.iterrows():
            individual_id = row['individualID']
            self.log(f"\nProcessing {individual_id} ({idx+1}/{len(df)})...")
            
            files_status = self.process_individual(row, file_mapping, fastq_columns, target_dir)
            
            # Log individual summary
            status_parts = []
            if files_status['intact']:
                status_parts.append(f"{len(files_status['intact'])} intact")
            if files_status['downloaded']:
                status_parts.append(f"{len(files_status['downloaded'])} downloaded")
            if files_status['failed']:
                status_parts.append(f"{len(files_status['failed'])} failed")
            
            status = ", ".join(status_parts) if status_parts else "no files"
            self.log(f"  Summary for {individual_id}: {status}")
            
            summary.append({
                'individualID': individual_id,
                'intact': len(files_status['intact']),
                'downloaded': len(files_status['downloaded']),
                'failed': len(files_status['failed']),
                'intact_files': files_status['intact'],
                'downloaded_files': files_status['downloaded'],
                'failed_files': files_status['failed']
            })
        
        return summary

    def generate_final_report(self, summary, target_dir):
        """Generate comprehensive final report"""
        runtime = time.time() - self.start_time
        
        self.log("="*70)
        self.log("FINAL SUMMARY REPORT")
        self.log("="*70)
        
        # Overall statistics
        self.log(f"Runtime: {runtime/60:.1f} minutes")
        self.log(f"Total expected files: {self.stats['total_expected']}")
        self.log(f"Files already intact: {self.stats['existing_intact']}")
        self.log(f"Corrupted files removed: {self.stats['existing_corrupted']}")
        self.log(f"New files downloaded: {self.stats['downloaded_new']}")
        self.log(f"Failed downloads: {self.stats['failed']}")
        
        # Calculate success rate
        success_rate = ((self.stats['existing_intact'] + self.stats['downloaded_new']) / 
                       max(self.stats['total_expected'], 1)) * 100
        self.log(f"Overall success rate: {success_rate:.1f}%")
        
        # Individual summaries
        self.log(f"\nDetailed summary by individual:")
        failed_individuals = []
        
        for item in summary:
            status_parts = []
            if item['intact'] > 0:
                status_parts.append(f"{item['intact']} intact")
            if item['downloaded'] > 0:
                status_parts.append(f"{item['downloaded']} downloaded")
            if item['failed'] > 0:
                status_parts.append(f"{item['failed']} failed")
                failed_individuals.append(item['individualID'])
            
            status = ", ".join(status_parts) if status_parts else "no files"
            self.log(f"  {item['individualID']}: {status}")
        
        # Storage summary
        all_fastq_files = []
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if file.endswith('.fastq.gz'):
                    all_fastq_files.append(os.path.join(root, file))
        
        total_size = sum(os.path.getsize(f) for f in all_fastq_files) / (1024**3)
        self.log(f"\nStorage summary:")
        self.log(f"  Total fastq.gz files: {len(all_fastq_files)}")
        self.log(f"  Total storage used: {total_size:.2f} GB")
        
        # Save detailed summary
        summary_df = pd.DataFrame(summary)
        summary_path = os.path.join(target_dir, "download_summary.csv")
        summary_df.to_csv(summary_path, index=False)
        self.log(f"\nDetailed summary saved to: {summary_path}")
        
        # Final status
        if self.stats['failed'] == 0:
            self.log(f"\n🎉 SUCCESS: All files downloaded successfully!")
        else:
            self.log(f"\n⚠️  WARNING: {self.stats['failed']} files could not be downloaded")
            if failed_individuals:
                self.log(f"Individuals with failures: {', '.join(failed_individuals)}")
        
        return success_rate >= 95  # Return True if 95%+ success rate

    def run(self):
        """Main execution function"""
        try:
            self.log("🧬 UNIFIED SYNAPSE DOWNLOADER STARTING")
            self.log("="*70)
            
            # Initialize Synapse client
            self.setup_synapse_client()
            
            # Load metadata
            df = self.load_metadata(CSV_FILE)
            
            # Get Synapse file mapping
            file_mapping = self.get_synapse_file_mapping(SYNAPSE_PROJECT_ID)
            
            # Extract fastq columns
            fastq_columns = self.extract_fastq_columns(df)
            
            if not fastq_columns:
                self.log("No fastq columns found in the CSV file!", "ERROR")
                return False
            
            # Phase 1: Check existing files for corruption
            self.check_existing_files(TARGET_DIR)
            
            # Phase 2: Download missing/corrupted files
            summary = self.run_download_phase(df, file_mapping, fastq_columns, TARGET_DIR)
            
            # Generate final report
            success = self.generate_final_report(summary, TARGET_DIR)
            
            return success
            
        except Exception as e:
            self.log(f"FATAL ERROR: {str(e)}", "ERROR")
            return False

def main():
    """Entry point"""
    downloader = SynapseUnifiedDownloader()
    success = downloader.run()
    
    if success:
        print("\n✅ Job completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Job completed with errors!")
        sys.exit(1)

if __name__ == "__main__":
    main()