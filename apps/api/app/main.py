
from fastapi import FastAPI

app = FastAPI(
    title="API Test",
    description="API de test déployée sur Google Cloud Run",
    version="1.0.0"
)


@app.get("/")
def root():
    return {"status": "OK"}


@app.get("/health")
def health():
    return {"status": "OK"}

