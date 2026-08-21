import os
from typing import List, Dict
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from core.config import settings

# Global dictionary to cache FAISS vectorstores in memory per document
# In a true production app, this would be loaded from disk per request or persisted in a database
_vectorstores: Dict[str, FAISS] = {}

class RagEngine:
    def __init__(self):
        # We use a lightweight local embedding model to ensure privacy and speed
        self.embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
        
        # Initialize Groq LLM (requires GROQ_API_KEY)
        # Using llama-3.1-8b-instant as previously proven successful
        api_key = os.getenv("GROQ_API_KEY", settings.GROQ_API_KEY)
        if api_key:
            self.llm = ChatGroq(temperature=0, groq_api_key=api_key, model_name="llama-3.1-8b-instant")
        else:
            self.llm = None
            
        # The STRICT Guardrail Prompt
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a highly analytical expert tutor for a Personal Learning OS. 
Your ONLY task is to answer the user's question based strictly on the provided context extracted from their document.

CRITICAL RULES:
1. You MUST NOT generate any information, facts, or answers that are not explicitly supported by the provided context.
2. If the context does not contain the answer, you MUST output exactly: 'I cannot find evidence for this in the current document.'
3. Do not hallucinate or rely on outside knowledge.

Context:
{context}"""),
            ("human", "{question}")
        ])

    def index_pdf(self, document_id: str, file_path: str):
        """Loads a PDF, chunks it, and creates a local FAISS index."""
        print(f"Indexing {document_id} from {file_path}...")
        loader = PyPDFLoader(file_path)
        docs = loader.load()
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000, 
            chunk_overlap=200
        )
        splits = text_splitter.split_documents(docs)
        
        # Create FAISS index and cache it
        vectorstore = FAISS.from_documents(documents=splits, embedding=self.embeddings)
        _vectorstores[document_id] = vectorstore
        
        print(f"Successfully indexed {len(splits)} chunks for {document_id}.")
        return len(splits)

    def ask_question(self, document_id: str, question: str) -> str:
        """Retrieves context from FAISS and asks the LLM."""
        if not self.llm:
            return "Error: GROQ_API_KEY is not configured on the AI Gateway."
            
        if document_id not in _vectorstores:
            return "Error: Document has not been indexed yet. Please import it again or wait for indexing."
            
        vectorstore = _vectorstores[document_id]
        retriever = vectorstore.as_retriever(search_kwargs={"k": 4})
        
        def format_docs(docs):
            return "\n\n".join(doc.page_content for doc in docs)
            
        rag_chain = (
            {"context": retriever | format_docs, "question": RunnablePassthrough()}
            | self.prompt
            | self.llm
            | StrOutputParser()
        )
        
        print(f"Generating answer for: {question}")
        return rag_chain.invoke(question)

# Singleton instance
rag_engine = RagEngine()
