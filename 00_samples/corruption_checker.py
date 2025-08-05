#!/usr/bin/env python3
"""
Quick standalone script to check integrity of downloaded fastq files
Can be run independently to identify corrupted files
Usage: python check_file_integrity.py [--remove-corrupted]
"""

import os
import gzip
import sys
import argparse
from pathlib import Path

TARGET_DIR = "/fs/scratch/PAS2598/senes_raw/CONTROLS"
MIN_FILE_SIZE_MB = 10  # Minimum expected file size in MB

def is_file_corrupted(file_path):
    """Check if a file is corrupted or incomplete"""
    if not os.path.exists(file_path):
        return True, "File does not exist"
    
    file_size = os.path.getsize(file_path)
    
    # Check if file is too small (likely incomplete)
    if file_size < MIN_FILE_SIZE_MB * 1024 * 1024:
        return True, f"File too small ({file_size / (1024*1024):.1f} MB < {MIN_FILE_SIZE_MB} MB)"
    
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

def main():
    """Check all fastq files for corruption"""
    parser = argparse.ArgumentParser(description="Check fastq file integrity")
    parser.add_argument("--remove-corrupted", action="store_true", 
                       help="Automatically remove corrupted files")
    args = parser.parse_args()
    
    print("🔍 Checking file integrity for all downloaded fastq files...")
    print("=" * 60)
    
    if not os.path.exists(TARGET_DIR):
        print(f"❌ Target directory does not exist: {TARGET_DIR}")
        sys.exit(1)
    
    all_files = []
    corrupted_files = []
    intact_files = []
    
    # Find all fastq.gz files
    for root, dirs, files in os.walk(TARGET_DIR):
        for file in files:
            if file.endswith('.fastq.gz'):
                file_path = os.path.join(root, file)
                all_files.append(file_path)
    
    if not all_files:
        print("❌ No fastq.gz files found in the target directory")
        sys.exit(1)
    
    print(f"Found {len(all_files)} fastq.gz files to check...")
    print()
    
    # Check each file
    for i, file_path in enumerate(all_files, 1):
        relative_path = os.path.relpath(file_path, TARGET_DIR)
        file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
        
        print(f"[{i:3d}/{len(all_files)}] Checking {relative_path} ({file_size:.1f} MB)...", end=" ")
        
        is_corrupt, reason = is_file_corrupted(file_path)
        
        if is_corrupt:
            print(f"❌ CORRUPTED - {reason}")
            corrupted_files.append((file_path, reason))
            
            if args.remove_corrupted:
                try:
                    os.remove(file_path)
                    print(f"    🗑️  Removed corrupted file")
                except Exception as e:
                    print(f"    ❌ Could not remove file: {e}")
        else:
            print("✅ OK")
            intact_files.append(file_path)
    
    # Summary
    print()
    print("=" * 60)
    print("INTEGRITY CHECK SUMMARY")
    print("=" * 60)
    print(f"Total files checked: {len(all_files)}")
    print(f"Intact files: {len(intact_files)}")
    print(f"Corrupted files: {len(corrupted_files)}")
    
    if corrupted_files:
        print()
        if args.remove_corrupted:
            print("🗑️  CORRUPTED FILES REMOVED:")
        else:
            print("🚨 CORRUPTED FILES FOUND:")
        print("-" * 40)
        for file_path, reason in corrupted_files:
            relative_path = os.path.relpath(file_path, TARGET_DIR)
            print(f"  {relative_path}")
            print(f"    Reason: {reason}")
        
        if not args.remove_corrupted:
            print()
            print("💡 TO REMOVE CORRUPTED FILES:")
            print("Run: python check_file_integrity.py --remove-corrupted")
            print("\nOr run the unified downloader to automatically fix them:")
            print("python synapse_unified_downloader.py")
        
        # Calculate storage freed by removing corrupted files
        if not args.remove_corrupted:
            total_corrupted_size = sum(os.path.getsize(f[0]) for f in corrupted_files if os.path.exists(f[0])) / (1024**3)
            print(f"\n📊 Removing corrupted files would free {total_corrupted_size:.2f} GB of storage.")
        
        sys.exit(1)  # Exit with error code if corrupted files found
    else:
        print()
        print("🎉 All files are intact! No corruption detected.")
        
        # Show total storage usage
        total_size = sum(os.path.getsize(f) for f in intact_files) / (1024**3)
        print(f"📊 Total storage used: {total_size:.2f} GB")

if __name__ == "__main__":
    main()
