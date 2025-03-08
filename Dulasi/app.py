import streamlit as st

def main():
    st.set_page_config(page_title="SriPedia")

    st.header("Chat with multiple PDFs :books:")
    st.text_input("Ask a question about your documents")

    with st.sidebar:
        st.subheader("Your documents")
        pdf_docs = st.file_uploader("Upload your PDFs here and click 'Process'", accept_multiple_files=True)
        st.button("Process")

if __name__ == '__main__':
    main()