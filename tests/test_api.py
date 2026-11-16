from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    assert client.get("/health").json() == {"status": "ok"}


def test_create_redirect_and_stats():
    code = client.post("/links", json={"url": "https://example.com"}).json()["code"]
    r = client.get(f"/{code}", follow_redirects=False)
    assert r.status_code in (302, 307)
    assert client.get(f"/links/{code}/stats").json()["clicks"] == 1


def test_not_found():
    assert client.get("/naoexiste").status_code == 404
    assert client.get("/links/naoexiste/stats").status_code == 404
