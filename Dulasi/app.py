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