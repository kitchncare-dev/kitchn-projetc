
from fastapi import FastAPI

VERSION = "1.0.0"

app = FastAPI(
    title="API Test",
    description="API de test déployée sur Google Cloud Run",
    version=VERSION
)


@app.get("/")
def root():
    return {"status": "OK"}


@app.get("/health")
def health():
    return {"status": "OK"}


@app.get("/version")
def version():
    return {"version": VERSION}

