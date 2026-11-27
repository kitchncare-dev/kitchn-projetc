
import sys
from pathlib import Path

# Ajoute apps/api dans le chemin de recherche Python
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {"status": "OK"}


def test_version():
    response = client.get("/version")

    assert response.status_code == 200
    assert response.json() == {"version": "1.0.0"}


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "OK"}

