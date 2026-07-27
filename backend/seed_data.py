"""
seed_data.py - Sample khet data insert karo database mein
Bihar ke ek kaalpi gaon ke 5 khet ke sample GPS boundaries

Run: python seed_data.py
(Make sure API server chal raha ho pehle: uvicorn main:app --reload --port 8000)
"""

import requests
import json

BASE_URL = "http://localhost:8000"

# Bihar ke paas (lat ~25.5, lon ~85.1) kaalpi GPS coordinates
SAMPLE_FIELDS = [
    {
        "name": "Ramesh ka Khet - Plot A",
        "owner_name": "Ramesh Kumar Yadav",
        "khasra_number": "125/3",
        "coordinates": [
            [85.1001, 25.5001],
            [85.1015, 25.5001],
            [85.1015, 25.4990],
            [85.1001, 25.4990],
            [85.1001, 25.5001],
        ]
    },
    {
        "name": "Suresh Chacha ka Dhan Ka Khet",
        "owner_name": "Suresh Prasad Singh",
        "khasra_number": "126/1",
        "coordinates": [
            [85.1020, 25.5005],
            [85.1035, 25.5005],
            [85.1038, 25.4995],
            [85.1025, 25.4992],
            [85.1018, 25.4998],
            [85.1020, 25.5005],
        ]
    },
    {
        "name": "Diyara Kshetra - Nadi Ke Paas",
        "owner_name": "Mohan Lal Mishra",
        "khasra_number": "130/7",
        "coordinates": [
            [85.1040, 25.5010],
            [85.1060, 25.5008],
            [85.1065, 25.4998],
            [85.1055, 25.4992],
            [85.1042, 25.4995],
            [85.1040, 25.5010],
        ]
    },
    {
        "name": "Gauri Devi ka Bari Zameen",
        "owner_name": "Gauri Devi (W/o Late Shivdayal)",
        "khasra_number": "118/2A",
        "coordinates": [
            [85.0985, 25.5012],
            [85.1000, 25.5012],
            [85.1002, 25.5002],
            [85.0988, 25.5000],
            [85.0983, 25.5006],
            [85.0985, 25.5012],
        ]
    },
    {
        "name": "Kali Mata Mandir ke Pichhe Wali Zameen",
        "owner_name": "Gram Panchayat - Dharampur",
        "khasra_number": "GP/15",
        "coordinates": [
            [85.1070, 25.5015],
            [85.1090, 25.5015],
            [85.1090, 25.5005],
            [85.1070, 25.5005],
            [85.1070, 25.5015],
        ]
    },
]


def main():
    print("🌾 Village Land Mapping - Sample Data Insert kar rahe hain...\n")

    for i, field in enumerate(SAMPLE_FIELDS, 1):
        try:
            resp = requests.post(f"{BASE_URL}/api/fields", json=field, timeout=10)
            if resp.status_code == 200:
                data = resp.json()["field"]
                print(f"✅ [{i}/5] '{data['name']}' inserted.")
                print(f"       Area  : {data['area_bigha']:.4f} Bigha  |  {data['area_acre']:.4f} Acre  |  {data['area_sqm']:.1f} sqm")
                print(f"       Perimeter: {data['perimeter_m']:.1f} m\n")
            else:
                print(f"❌ [{i}/5] Failed to insert '{field['name']}': {resp.text}\n")
        except Exception as e:
            print(f"❌ [{i}/5] Error: {e}")
            print("   Kya API server chal raha hai? Run: uvicorn main:app --reload --port 8000\n")

    print("✅ Sample data insertion complete!")
    print(f"📖 API Docs: {BASE_URL}/docs")
    print(f"📋 All Fields: {BASE_URL}/api/fields")


if __name__ == "__main__":
    main()
