"""Shortly - encurtador de URLs (versão mínima para o PGCS)."""
import secrets

from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel

app = FastAPI(title="Shortly")
_links: dict[str, dict] = {}


class LinkIn(BaseModel):
    url: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/links", status_code=201)
def create_link(body: LinkIn):
    code = secrets.token_urlsafe(4)
    _links[code] = {"url": body.url, "clicks": 0}
    return {"code": code, "url": body.url}


@app.get("/{code}")
def redirect(code: str):
    link = _links.get(code)
    if not link:
        raise HTTPException(status_code=404, detail="link não encontrado")
    link["clicks"] += 1
    return RedirectResponse(link["url"])


@app.get("/links/{code}/stats")
def stats(code: str):
    link = _links.get(code)
    if not link:
        raise HTTPException(status_code=404, detail="link não encontrado")
    return {"code": code, "clicks": link["clicks"]}
