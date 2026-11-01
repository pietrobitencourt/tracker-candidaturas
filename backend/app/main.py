from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def raiz():
    return {"mensagem": "Tracker de Candidaturas: API no ar"}
