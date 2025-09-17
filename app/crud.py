from sqlalchemy.orm import Session
from . import models, schemas

# --- LÓGICA PARA EL CHECKLIST ---

def get_checklist_data(db: Session):
    """
    Obtiene todas las categorías y, para cada una, anida sus ítems (preguntas).
    """
    # 1. Obtiene todas las categorías de la base de datos.
    categorias = db.query(models.ChecklistCategoria).all()
    # 2. Obtiene todos los ítems de la base de datos.
    items = db.query(models.ChecklistItem).all()

    # 3. Crea un diccionario para organizar los datos eficientemente.
    #    La clave es el ID de la categoría.
    categorias_dict = {
        cat.id: schemas.ChecklistCategoriaBase(id=cat.id, nombre=cat.nombre, items=[]) 
        for cat in categorias
    }

    # 4. Recorre cada ítem y lo agrega a la lista de su categoría correspondiente.
    for item in items:
        if item.categoria_id in categorias_dict:
            categorias_dict[item.categoria_id].items.append(
                schemas.ChecklistItemBase(id=item.id, pregunta_texto=item.pregunta_texto)
            )
    
    # 5. Devuelve una lista con todas las categorías ya organizadas.
    return list(categorias_dict.values())


# --- LÓGICA PARA LAS VISITAS ---

def create_visita_y_respuestas(db: Session, visita_data: schemas.VisitaCreate):
    """
    Guarda una visita principal y luego guarda cada una de sus respuestas
    del checklist asociadas.
    """
    # NOTA: Esta función usa los modelos Visita y VisitaRespuesta que ya no existen
    # Se mantiene comentada por compatibilidad histórica
    # Para crear visitas, usar el endpoint /api/visitas-completas-pae
    raise Exception("Esta función está deshabilitada. Use /api/visitas-completas-pae para crear visitas.")