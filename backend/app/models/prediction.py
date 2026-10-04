from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from datetime import datetime
from app.database.connection import Base

class PredictionModel(Base):
    __tablename__ = "prediccion"  # Nombre exacto de la tabla en tu PostgreSQL

    id_prediccion = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("usuario.id_usuario", ondelete="CASCADE"), nullable=False)
    clasificacion = Column(String(100), nullable=False)
    enfermedad = Column(String(100), nullable=False)
    confianza = Column(Float, nullable=False)
    fecha = Column(DateTime, default=datetime.utcnow)
    zona_cuerpo = Column(String(50), nullable=True)
    url_imagen = Column(String, nullable=False)