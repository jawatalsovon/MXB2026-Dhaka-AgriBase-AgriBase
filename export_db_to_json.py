#!/usr/bin/env python3
"""
Script to extract SQLite databases and convert to optimized JSON format for web.
Aggregates data into clean structures for efficient web querying.
"""

import sqlite3
import json
import sys
from pathlib import Path
from datetime import datetime
# 
def dict_from_row(row):
    """Convert sqlite3.Row to dict"""
    return dict(row) if row else {}

def export_crops_db(db_path, output_json_path):
    """Export crops.db into aggregated JSON format"""
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get crop_data table
        cursor.execute('SELECT * FROM crop_data')
        crop_rows = cursor.fetchall()
        
        # Get crop_predictions table
        cursor.execute('SELECT * FROM crop_predictions')
        pred_rows = cursor.fetchall()
        
        conn.close()
        
        # Convert to list of dicts
        crops = [dict(row) for row in crop_rows]
        predictions = [dict(row) for row in pred_rows]
        
        # Create aggregated structure
        data = {
            'crops': crops,
            'predictions': predictions,
            'metadata': {
                'exported': datetime.now().isoformat(),
                'source': 'crops.db',
                'total_crop_records': len(crops),
                'total_prediction_records': len(predictions),
            }
        }
        
        # Write to JSON
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        
        print(f"✓ Exported crops.db to {output_json_path}")
        print(f"  - {len(crops)} crop records")
        print(f"  - {len(predictions)} prediction records")
        return True
    except Exception as e:
        print(f"✗ Error exporting crops.db: {e}")
        return False

def export_predictions_db(db_path, output_json_path):
    """Export predictions.db into aggregated JSON format"""
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get all prediction tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        tables = [row[0] for row in cursor.fetchall()]
        
        all_predictions = []
        
        for table in tables:
            try:
                cursor.execute(f'SELECT * FROM "{table}"')
                rows = cursor.fetchall()
                for row in rows:
                    row_dict = dict(row)
                    row_dict['_source_table'] = table
                    all_predictions.append(row_dict)
            except Exception as e:
                print(f"  Warning: Could not read {table}: {e}")
        
        conn.close()
        
        # Create aggregated structure
        data = {
            'predictions': all_predictions,
            'metadata': {
                'exported': datetime.now().isoformat(),
                'source': 'predictions.db',
                'total_records': len(all_predictions),
                'source_tables': len(tables),
            }
        }
        
        # Write to JSON
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        
        print(f"✓ Exported predictions.db to {output_json_path}")
        print(f"  - {len(all_predictions)} total prediction records")
        print(f"  - From {len(tables)} source tables")
        return True
    except Exception as e:
        print(f"✗ Error exporting predictions.db: {e}")
        return False

def export_attempt_db(db_path, output_json_path):
    """Export attempt.db into aggregated JSON format"""
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get all relevant tables (skip summary tables for now)
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'pie_%'")
        tables = [row[0] for row in cursor.fetchall()]
        
        all_data = []
        
        for table in tables:
            try:
                cursor.execute(f'SELECT * FROM "{table}"')
                rows = cursor.fetchall()
                for row in rows:
                    row_dict = dict(row)
                    row_dict['_source_table'] = table
                    all_data.append(row_dict)
            except Exception as e:
                print(f"  Warning: Could not read {table}: {e}")
        
        conn.close()
        
        # Create aggregated structure
        data = {
            'attempt': all_data,
            'metadata': {
                'exported': datetime.now().isoformat(),
                'source': 'attempt.db',
                'total_records': len(all_data),
                'source_tables': len(tables),
            }
        }
        
        # Write to JSON
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        
        print(f"✓ Exported attempt.db to {output_json_path}")
        print(f"  - {len(all_data)} total records")
        print(f"  - From {len(tables)} source tables")
        return True
    except Exception as e:
        print(f"✗ Error exporting attempt.db: {e}")
        return False

def main():
    # Database paths
    db_dir = Path('app/assets/databases')
    json_dir = Path('app/assets/json')
    
    # Create json directory if it doesn't exist
    json_dir.mkdir(parents=True, exist_ok=True)
    
    print("Exporting databases to optimized JSON format...\n")
    
    success = True
    
    # Export crops.db
    crops_db = db_dir / 'crops.db'
    if crops_db.exists():
        print("Processing crops.db...")
        if not export_crops_db(str(crops_db), str(json_dir / 'crop_data.json')):
            success = False
    else:
        print(f"⚠ {crops_db} not found")
    
    # Export predictions.db
    print()
    pred_db = db_dir / 'predictions.db'
    if pred_db.exists():
        print("Processing predictions.db...")
        if not export_predictions_db(str(pred_db), str(json_dir / 'prediction_data.json')):
            success = False
    else:
        print(f"⚠ {pred_db} not found")
    
    # Export attempt.db
    print()
    attempt_db = db_dir / 'attempt.db'
    if attempt_db.exists():
        print("Processing attempt.db...")
        if not export_attempt_db(str(attempt_db), str(json_dir / 'attempt_data.json')):
            success = False
    else:
        print(f"⚠ {attempt_db} not found")
    
    print()
    if success:
        print("✓ All databases exported successfully!")
        print(f"JSON files created in: {json_dir}")
    else:
        print("✗ Some exports failed")
        sys.exit(1)

if __name__ == '__main__':
    main()

