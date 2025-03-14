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

def get_embedding(text_chunks, user_id,  model_id="text-embedding-ada-002"):
    points = []
    for idx, chunk in enumerate(text_chunks):
        response = client.embeddings.create(
            input=chunk,
            model=model_id
        )
        embeddings = response.data[0].embedding
        point_id = str(uuid.uuid4())  # Generate a unique ID for the point

        points.append(PointStruct(id=point_id, vector=embeddings, payload={"text": chunk, "user_id": user_id}))

    return points

def insert_data(get_points):
    connection = create_cluster_in_qdrant()
    operation_info = connection.upsert(
    collection_name="SriPedia",
    wait=True,
    points=get_points
)
    
def create_answer_with_context(query, user_id):  # Add user_id parameter
    # Generate query embedding
    response = client.embeddings.create(
        input=query,
        model="text-embedding-ada-002"
    )
    embeddings = response.data[0].embedding
    
    # Create user-specific filter
    user_filter = models.Filter(
        must=[models.FieldCondition(
            key="user_id",  # Metadata field storing user IDs
            match=models.MatchValue(value=user_id)
        )]
    )
    
    # Search with filter
    connection = create_cluster_in_qdrant()
    search_result = connection.search(
        collection_name="SriPedia",
        query_vector=embeddings,
        query_filter=user_filter,  # Apply metadata filter
        limit=3  # Increase for better recall
    )

    prompt = "Context:\n"
    for result in search_result:
        prompt += result.payload['text'] + "\n---\n"
    prompt += "Question:" + query + "\n---\n" + "Answer:"

    print("----PROMPT START----")
    print(":", prompt)
    print("----PROMPT END----")

    completion = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": prompt}
        ]
        )

    return completion.choices[0].message.content

def delete_collection(collection_name_to_delete):
    connection = create_cluster_in_qdrant()
    connection.delete_collection(collection_name=collection_name_to_delete)




@app.route('/')
def home():
    return jsonify({"message": "Welcome to the Flask API!"})

@app.route('/addDocuments', methods=['POST'])
def add_documents():
    """
    Upload a PDF document
    ---
    parameters:
      - name: pdf
        in: formData
        type: file
        required: true
        description: The PDF file to upload
      - name: user_id
        in: formData
        type: string
        required: true
        description: The ID of the user uploading the document
    responses:
      200:
        description: Success message
    """
    if 'pdf' not in request.files or 'user_id' not in request.form:
        return jsonify({"error": "Missing PDF or user_id"}), 400
    
    try:
        pdf = request.files['pdf']
        user_id = request.form['user_id']
        get_raw_text = read_data_from_pdf(pdf)
        chunks=get_text_chunks(get_raw_text)
        vectors=get_embedding(chunks, user_id)
        insert_data(vectors)
        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/askQuestion', methods=['GET'])
def ask_question():
    """
    Ask a question based on uploaded documents
    ---
    parameters:
      - name: question
        in: query
        type: string
        required: true
        description: The question to ask
      - name: user_id
        in: query
        type: string
        required: true
        description: The ID of the user asking the question
    responses:
      200:
        description: The answer to the question
    """
    question = request.args.get("question")
    user_id = request.args.get("user_id")
    if not question or not user_id:
        return jsonify({"error": "Missing question or user_id"}), 400
    answer=create_answer_with_context(question, user_id)
    return jsonify({"answer": answer})

@app.route('/deleteCollection', methods=['DELETE'])
def delete_collection_route():
    """
    Delete a Qdrant collection
    ---
    parameters:
      - name: collection_name
        in: query
        type: string
        required: true
        description: The name of the collection to delete
    responses:
      200:
        description: Collection deleted successfully
      400:
        description: Missing or invalid collection name
      500:
        description: Internal server error
    """
    collection_name = request.args.get('collection_name')
    if not collection_name:
        return jsonify({"error": "Missing collection_name"}), 400

    try:
        delete_collection(collection_name)
        return jsonify({"message": f"Collection '{collection_name}' deleted successfully."}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/favicon.ico')
def favicon():
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
