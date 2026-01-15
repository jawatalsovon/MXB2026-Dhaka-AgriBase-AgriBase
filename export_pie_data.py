#!/usr/bin/env python3
"""
Script to export pie chart CSV files to JSON format for web compatibility.
"""

import csv
import json
from pathlib import Path
from datetime import datetime

def export_csv_to_json(csv_path, output_json_path):
    """Convert CSV file to JSON list of dicts"""
    try:
        data = []
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Convert numeric strings to numbers
                converted_row = {}
                for key, value in row.items():
                    if value and value.replace('.', '', 1).replace('-', '', 1).isdigit():
                        try:
                            converted_row[key] = float(value) if '.' in value else int(value)
                        except ValueError:
                            converted_row[key] = value
                    else:
                        converted_row[key] = value
                data.append(converted_row)
        
        return data
    except Exception as e:
        print(f"Error reading {csv_path}: {e}")
        return []

def main():
    data_dir = Path('data/pie')
    json_dir = Path('app/assets/json')
    
    json_dir.mkdir(parents=True, exist_ok=True)
    
    # List of pie data files
    pie_files = {
        'pie_crop_area.csv': 'pie_crop_area',
        'pie_fibre_area.csv': 'pie_fibre_area',
        'pie_narcos_area.csv': 'pie_narcos_area',
        'pie_oilseed_area.csv': 'pie_oilseed_area',
        'pie_pulse_area.csv': 'pie_pulse_area',
        'pie_rice_area.csv': 'pie_rice_area',
        'pie_spices_area.csv': 'pie_spices_area',
        'pie_suger_area.csv': 'pie_suger_area',
    }
    
    print("Exporting pie chart data to JSON format...\n")
    
    all_pie_data = {}
    
    for csv_name, data_key in pie_files.items():
        csv_path = data_dir / csv_name
        if not csv_path.exists():
            print(f"⚠ File not found: {csv_path}")
            continue
        
        print(f"Processing {csv_name}...")
        data = export_csv_to_json(csv_path, None)
        all_pie_data[data_key] = data
        print(f"  ✓ Loaded {len(data)} records")
    
    # Create aggregated pie data file
    output_path = json_dir / 'pie_data.json'
    aggregated_data = {
        'pie_data': all_pie_data,
        'metadata': {
            'exported': datetime.now().isoformat(),
            'source': 'CSV files from data/pie/',
            'total_categories': len(all_pie_data),
        }
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(aggregated_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ Exported pie data to {output_path}")
    print(f"  - {len(all_pie_data)} pie chart categories")
    total_records = sum(len(v) for v in all_pie_data.values())
    print(f"  - {total_records} total records")

if __name__ == '__main__':
    main()
