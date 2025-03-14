# flask imports
import json
from flask import Flask, jsonify, request
from dotenv import load_dotenv

# llm imports
from PyPDF2 import PdfReader
from langchain.text_splitter import CharacterTextSplitter
from langchain_community.vectorstores import Qdrant
from langchain_community.embeddings import OpenAIEmbeddings
from qdrant_client import QdrantClient,models
from qdrant_client.http.models import PointStruct
import os
from openai import OpenAI
import uuid
from qdrant_client.http.exceptions import UnexpectedResponse
from flasgger import Swagger

# Setting things up for llm
app = Flask(__name__)
swagger = Swagger(app)

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def create_cluster_in_qdrant():
    record=0
    connection = QdrantClient(
    url=os.getenv("QDRANT_URL"),
    api_key=os.getenv("QDRANT_API_KEY")
)

    try:
        connection.get_collection("SriPedia")
    except UnexpectedResponse as e:
        connection.create_collection(
            collection_name="SriPedia",
            vectors_config=models.VectorParams(size=1536, distance=models.Distance.COSINE),
        )  # Use create instead of recreate
    

    print("Create collection reponse:", connection)

    info = connection.get_collection(collection_name="SriPedia")

    return connection

def read_data_from_pdf(pdf_file):
    text = ""  # for storing the extracted text

    text = ""
    pdf_reader = PdfReader(pdf_file.stream)  # Read from file stream
    for page in pdf_reader.pages:
        text += page.extract_text()
    return text

def get_text_chunks(text):
    text_splitter = CharacterTextSplitter(
        separator="\n",
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len
    )
    chunks = text_splitter.split_text(text)
    return chunks

