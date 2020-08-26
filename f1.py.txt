import pandas as pd
from flask import Flask, render_template, request, make_response, g, abort

app = Flask(__name__)

def pegaDataFrame():
  if not hasattr(g, 'f1df'):
    g.f1df = pd.read_csv("https://github.com/godoy42/cst_cd_3p_dv/raw/master/resultados_f1.csv", encoding="UTF8", index_col=0)
  return g.f1df.rename(columns={
      "constructorId": "id_equipe", "driverId": "id_piloto", "circuitId": "id_circuito"}
      )

@app.route("/", methods=['POST','GET'])
def hello():
  resp = make_response(render_template(
      'index.html',
      titulo="Dados da F1",
      ))
  return resp

####   Metodos para equipes  ####
@app.route("/equipe", methods=['GET'])
def listaEquipes():
  df = pegaDataFrame()
  return df[["id_equipe", "nome_equipe"]].drop_duplicates().to_json(orient="records")

@app.route("/equipe/<int:idEquipe>", methods=['GET'])
def pegaUmaEquipe(idEquipe):
  df = pegaDataFrame()
  dadosEquipe = df[df["id_equipe"] == idEquipe][["id_equipe", "nome_equipe", "pais_equipe", "nome_piloto", "id_piloto", "position"]].drop_duplicates()
  if len(dadosEquipe) == 0:
    abort(404)
  
  equipe = dadosEquipe[["id_equipe", "nome_equipe", "pais_equipe"]].iloc[0].to_dict()
  #originalmente o datatype int64 desse campo interfere com a serialização no fim.
  #somente forçar o tipo, mais rápido que ter que implementar uma solução genérica
  equipe["id_equipe"] = int(equipe["id_equipe"])

  equipe["pilotos"] = dadosEquipe[["nome_piloto", "id_piloto"]].drop_duplicates().to_dict(orient="records")
  equipe["podiums"] = len(dadosEquipe[dadosEquipe["position"] < 4])

  return equipe


####   Metodos para pilotos  ####
@app.route("/piloto", methods=['GET'])
def listaPilotos():
  df = pegaDataFrame()
  return df[["id_piloto", "nome_piloto"]].drop_duplicates().to_json(orient="records")

@app.route("/piloto/<int:idPiloto>", methods=['GET'])
def pegaUmPiloto(idPiloto):
  print(f"buscando {idPiloto}")
  df = pegaDataFrame()
  dadosPiloto = df[df["id_piloto"] == idPiloto][["id_equipe", "nome_equipe", "pais_piloto", "nome_piloto", "id_piloto", "position", "points", "year", "data_nascimento"]].drop_duplicates()
  if len(dadosPiloto) == 0:
    abort(404)

  piloto = dadosPiloto[["id_piloto", "nome_piloto", "pais_piloto", "data_nascimento"]].iloc[0].to_dict()
  #originalmente o datatype int64 desse campo interfere com a serialização no fim.
  #somente forçar o tipo, mais rápido que ter que implementar uma solução genérica
  piloto["id_piloto"] = int(piloto["id_piloto"])

  df = pegaDataFrame()
  piloto["equipes"] = dadosPiloto[["nome_equipe", "id_equipe"]].drop_duplicates().to_dict(orient="records")
  piloto["podiums"] = len(dadosPiloto[dadosPiloto["position"] < 4])
  piloto["total_pontos"] = int(dadosPiloto["points"].sum())
  piloto["melhor_ano"] = int(dadosPiloto.groupby(by="year")[["points"]].sum().sort_values(by="points", ascending=False).iloc[[0]].reset_index()["year"][0])

  return piloto


####   Metodos para circuitos  ####
@app.route("/circuito", methods=['GET'])
def listaCircuitos():
  df = pegaDataFrame()
  return df[["id_circuito", "nome_circuito"]].drop_duplicates().to_json(orient="records")

@app.route("/circuito/<idCircuito>", methods=['GET'])
def buscaUmCircuito(idCircuito):
  df = pegaDataFrame()
  circuitos = df[["id_circuito", "nome_circuito", "pais_circuito", "laps", "year", "id_piloto", "nome_piloto"]]
  circuitos = circuitos[circuitos["id_circuito"] == idCircuito]

  if len(circuitos) == 0:
    abort(404)
  
  circuito = circuitos[["id_circuito", "nome_circuito", "pais_circuito"]].iloc[0].to_dict()
  circuito["id_circuito"] = int(circuito["id_circuito"])
  circuito["provas"] = len(circuitos[["year"]].drop_duplicates())
  circuito["voltas"] = int(circuitos[["laps"]].max().values[0])
  return circuito


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
