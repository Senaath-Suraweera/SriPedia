import streamlit as st
from dotenv import load_dotenv
from PyPDF2 import PdfReader
from langchain.text_splitter import CharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationalRetrievalChain
from langchain_community.chat_models import ChatOpenAI

def get_pdf_text(pdf_docs):
    text = ""
    for pdf in pdf_docs:
        pdf_reader = PdfReader(pdf)
        for page in pdf_reader.pages:
            text += page.extract_text()
    return text

def get_text_chunks(text):
    text_splitter = CharacterTextSplitter(separator="\n", chunk_size=1000, chunk_overlap=200, length_function=len)
    chunks = text_splitter.split_text(text)
    return chunks

def get_vectorstore(text_chunks):  
    try:
        embeddings = OpenAIEmbeddings()
        vectorstore = FAISS.from_texts(texts=text_chunks, embedding=embeddings)
        return vectorstore
    except Exception as e:
        st.error(f"Error creating vector store: {e}")
        return None

def get_conversation_chain(vectorstore):
    llm = ChatOpenAI()
    memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)
    conversation_chain = ConversationalRetrievalChain.from_llm(
        llm=llm,
        retriever=vectorstore.as_retriever(),
        memory=memory
    )
    return conversation_chain

def main():
    load_dotenv()
    st.set_page_config(page_title="SriPedia")

    if "conversation" not in st.session_state:
        st.session_state.conversation = None

    # Initialize session state variables
    if "conversation" not in st.session_state:
        st.session_state.conversation = None
    if "vectorstore" not in st.session_state:
        st.session_state.vectorstore = None

    st.header("Chat with multiple PDFs :books:")
    user_question = st.text_input("Ask a question about your documents")

    if user_question and st.session_state.conversation:
        response = st.session_state.conversation.run(user_question)
        st.write(response)

    with st.sidebar:
        st.subheader("Your documents")
        pdf_docs = st.file_uploader("Upload your PDFs here and click 'Process'", type="pdf", accept_multiple_files=True)
        if st.button("Process"):
            with st.spinner("Processing..."):
                try:
                    # Get PDF text
                    raw_text = get_pdf_text(pdf_docs)
                    if not raw_text:
                        st.error("No text extracted from the PDFs. Please check the files.")
                        return
                    st.write(raw_text)

                    # Get the text chunks
                    text_chunks = get_text_chunks(raw_text)
                    if not text_chunks:
                        st.error("No text chunks generated. Please check the input text.")
                        return
                    st.write(text_chunks)

                    # Create vector store
                    vectorstore = get_vectorstore(text_chunks)
                    if vectorstore is None:
                        st.error("Failed to create vector store. Please check the embeddings.")
                        return

                    # Store vectorstore in session state
                    st.session_state.vectorstore = vectorstore

                    # Create conversation chain
                    st.session_state.conversation = get_conversation_chain(vectorstore)
                    st.success("Processing complete!")
                except Exception as e:
                    st.error(f"An error occurred: {e}")             

if __name__ == '__main__':
    main()