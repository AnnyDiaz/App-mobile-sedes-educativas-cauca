--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: checklist_categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checklist_categorias (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL
);


ALTER TABLE public.checklist_categorias OWNER TO postgres;

--
-- Name: checklist_categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.checklist_categorias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.checklist_categorias_id_seq OWNER TO postgres;

--
-- Name: checklist_categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.checklist_categorias_id_seq OWNED BY public.checklist_categorias.id;


--
-- Name: checklist_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checklist_items (
    id integer NOT NULL,
    pregunta_texto text NOT NULL,
    categoria_id integer NOT NULL,
    orden integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.checklist_items OWNER TO postgres;

--
-- Name: checklist_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.checklist_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.checklist_items_id_seq OWNER TO postgres;

--
-- Name: checklist_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.checklist_items_id_seq OWNED BY public.checklist_items.id;


--
-- Name: instituciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instituciones (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    dane character varying(20),
    municipio_id integer
);


ALTER TABLE public.instituciones OWNER TO postgres;

--
-- Name: instituciones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.instituciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.instituciones_id_seq OWNER TO postgres;

--
-- Name: instituciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.instituciones_id_seq OWNED BY public.instituciones.id;


--
-- Name: municipios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.municipios (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE public.municipios OWNER TO postgres;

--
-- Name: municipios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.municipios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.municipios_id_seq OWNER TO postgres;

--
-- Name: municipios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.municipios_id_seq OWNED BY public.municipios.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sedes_educativas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sedes_educativas (
    id integer NOT NULL,
    nombre_sede character varying NOT NULL,
    dane character varying NOT NULL,
    due character varying NOT NULL,
    lat double precision,
    lon double precision,
    principal boolean,
    municipio_id integer NOT NULL,
    institucion_id integer NOT NULL
);


ALTER TABLE public.sedes_educativas OWNER TO postgres;

--
-- Name: sedes_educativas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sedes_educativas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sedes_educativas_id_seq OWNER TO postgres;

--
-- Name: sedes_educativas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sedes_educativas_id_seq OWNED BY public.sedes_educativas.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    correo character varying NOT NULL,
    contrasena character varying NOT NULL,
    rol_id integer NOT NULL
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: visita_respuestas_completas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visita_respuestas_completas (
    id integer NOT NULL,
    visita_completa_id integer NOT NULL,
    item_id integer NOT NULL,
    respuesta character varying NOT NULL,
    observacion text
);


ALTER TABLE public.visita_respuestas_completas OWNER TO postgres;

--
-- Name: visita_respuestas_completas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visita_respuestas_completas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visita_respuestas_completas_id_seq OWNER TO postgres;

--
-- Name: visita_respuestas_completas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visita_respuestas_completas_id_seq OWNED BY public.visita_respuestas_completas.id;


--
-- Name: visitas_completas_pae; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visitas_completas_pae (
    id integer NOT NULL,
    fecha_visita timestamp without time zone NOT NULL,
    contrato character varying NOT NULL,
    operador character varying NOT NULL,
    caso_atencion_prioritaria character varying,
    municipio_id integer,
    institucion_id integer,
    sede_id integer,
    profesional_id integer,
    fecha_creacion timestamp without time zone,
    estado character varying,
    observaciones text,
    foto_evidencia character varying,
    video_evidencia character varying,
    audio_evidencia character varying,
    pdf_evidencia character varying,
    foto_firma character varying
);


ALTER TABLE public.visitas_completas_pae OWNER TO postgres;

--
-- Name: visitas_completas_pae_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visitas_completas_pae_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visitas_completas_pae_id_seq OWNER TO postgres;

--
-- Name: visitas_completas_pae_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visitas_completas_pae_id_seq OWNED BY public.visitas_completas_pae.id;


--
-- Name: checklist_categorias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_categorias ALTER COLUMN id SET DEFAULT nextval('public.checklist_categorias_id_seq'::regclass);


--
-- Name: checklist_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_items ALTER COLUMN id SET DEFAULT nextval('public.checklist_items_id_seq'::regclass);


--
-- Name: instituciones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instituciones ALTER COLUMN id SET DEFAULT nextval('public.instituciones_id_seq'::regclass);


--
-- Name: municipios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipios ALTER COLUMN id SET DEFAULT nextval('public.municipios_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sedes_educativas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas ALTER COLUMN id SET DEFAULT nextval('public.sedes_educativas_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: visita_respuestas_completas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visita_respuestas_completas ALTER COLUMN id SET DEFAULT nextval('public.visita_respuestas_completas_id_seq'::regclass);


--
-- Name: visitas_completas_pae id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae ALTER COLUMN id SET DEFAULT nextval('public.visitas_completas_pae_id_seq'::regclass);


--
-- Data for Name: checklist_categorias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.checklist_categorias (id, nombre) FROM stdin;
1	Numero de manipuladoras encontradas
2	Diseño, construccion y disposicion de residuos solidos
3	Equipos y utensilios
4	Personal manipulador
5	Practicas Higienicas y Medidas de Proteccion
6	Materias primas e insumos
7	Operaciones de fabricacion
8	Prevencion de la contaminacion cruzada
9	Aseguramiento y control de la calidad e inocuidad
10	Saneamiento
11	Almacenamiento
12	Transporte
13	Distribucion y consumo
14	Documentacion PAE
15	Cobertura
\.


--
-- Data for Name: checklist_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.checklist_items (id, pregunta_texto, categoria_id, orden) FROM stdin;
50	La cantidad de manipuladoras corresponde al numero de cupos asignados.	1	50
68	El personal manipulador no presenta afecciones de la piel o enfermedad infectocontagiosa.	5	68
51	En caso de no contar con el numero de manipuladoras corespondiente, se encuentra el documento de justificacion debidamente firmado, donde se especifique la razon por la que no se cumple con este personal y el acuerdo previamente establecido.	1	51
52	No se evidencia presencia de animales en el establecimiento, especificamente en las areas destinadas a la fabricacion, procesamiento, preparacion, envase, almacenamiento y expendio.	2	52
53	No se permite el almacenamiento de elementos, productos quimicos o peligrosos ajenos a las actividades propias realizadas en este.	2	53
54	Los residuos solidos que se generan en el comedor escolar se encuentran ubicados de manera que no representen riesgo de contaminacion para el alimento, para los ambientes o superficies de potencial contacto con este.	2	54
55	Los residuos solidos son removidos frecuentemente de las areas de produccion y estan ubicados de manera que se evite la generacion de malos olores, el refugio de animales y plagas y que ademas no contribuya al deterioro ambiental.	2	55
56	Los recipientes utilizados para almacenamiento de residuos organicos e inorganicos, son a prueba de fugas, debidamente identificados, construidos de material impermeable, de facil limpieza y desinfeccion y de ser requerido estan provistos de tapa hermetica, dichos recipientes no pueden utilizarse para contener productos comestibles.	2	56
57	El personal manipulador cuenta con certificacion medica, la cual especifique ser apto(a) para manipular alimentos.	4	57
58	Se cuenta con un plan de capacitacion continuo y permanente para el personal manipulador de alimentos desde el momento de su contratacion y luego ser reforzado mediante charlas, cursos u otros medios efectivos de actualizacion. Dicho plan debe ser de por lo menos 10 horas anuales, sobre asuntos especificos relacionados al tema.	4	58
59	El manipulador de alimentos se encuentra capacitado para comprender y manejar el control de los puntos del proceso que estan bajo su responsabilidad y la importancia de su vigilancia o monitoreo; ademas, conoce los limites del punto del proceso y las acciones correctivas a tomar cuando existan desviaciones en dichos limites.	4	59
60	El personal manipulador cuenta con una estricta limpieza e higiene personal y aplica buenas practicas higienicas en sus labores, de manera que se evite la contaminacion del alimento y de las superficies de contacto con este.	5	60
61	El personal manipulador usa vestimenta de trabajo que cumpla los siguientes requisitos: De color claro que permita visualizar facilmente su limpieza; con cierres o cremalleras y/o broches en lugar de botones u otros accesorios que puedan caer en el alimento; sin bolsillos ubicados por encima de la cintura; usa calzado cerrado, de material resistente e impermeable y de tacon bajo. Cuando se utiliza delantal, este permanece atado al cuerpo en forma segura.	5	61
62	El operador hace entrega de la dotacion completa al personal manipulador, conformada por (camisa, pantalon, cofia, tapaboca, delantal y calzado cerrado) en la cantidad establecida en el contrato vigente y de acuerdo con lo estipulado en el anexo tecnico. En caso que por usos y costumbres el personal manipulador no utilice la dotacion establecida, se cuenta con la certificacion firmada por el personal manipulador.	5	62
63	El operador entrega en el periodo los siguientes elementos de higiene para cada manipulador (a): * 1 Jabon antibacterial inoloro en cantidad mayor o igual a 300 mL/cc * 1 Rollo de papel higienico	5	63
64	El personal manipulador se lava y desinfecta las manos con agua y jabon antibacterial, antes de comenzar su trabajo, cada vez que salga y regrese al area asignada y despues de manipular cualquier material u objeto que pudiese representar un riesgo de contaminacion para el alimento.	5	64
65	El personal manipulador cumple: * Mantiene el cabello recogido y cubierto totalmente mediante malla, gorro u otro medio efectivo y en caso de llevar barba, bigote o patillas usa cubiertas para estas. *No usa maquillaje.* utiliza tapabocas cubriendo nariz y boca mientras se manipula el alimento. *Mantiene las uñas cortas, limpias y sin esmalte. * No utiliza reloj, anillos, aretes, joyas u otros accesorios mientras realice sus labores. En caso de usar lentes, deben asegurarse a la cabeza mediante bandas, cadenas u otros medios ajustables.	5	65
66	De ser necesario el uso de guantes, estos se mantienen limpios, sin roturas o desperfectos y son tratados con el mismo cuidado higienico de las manos sin proteccion. El material de los guantes, es apropiado para la operacion realizada y evitan la acumulacion de humedad y contaminacion en su interior para prevenir posibles afecciones cutaneas de los operarios. El uso de guantes no exime al operario de la obligacion de lavarse las manos.	5	66
67	El personal manipulador no realiza actividades como: Beber o masticar cualquier objeto o producto, fumar o escupir en las areas de produccion o en cualquier otra zona donde exista riesgo de contaminacion del alimento.	5	67
69	Los visitantes de los establecimientos cumplen estrictamente todas las practicas de higiene y portan la vestimenta y/o dotacion adecuada.	5	69
70	La recepcion de materias primas se realiza en condiciones que eviten su contaminacion, alteracion y daños fisicos y estan debidamente identificadas de conformidad con la Resolucion 5109 de 2005 o las normas que la modifiquen, adicionen o sustituyan, y para el caso de los insumos, deben cumplir con las resoluciones 1506 de 2011 y/o la 683 de 2012, segun corresponda, o las normas que las modifiquen, adicionen o sustituyan.	6	70
71	Las materias primas son sometidas a limpieza con agua potable u otro medio adecuado de ser requerido, se aplica la descontaminacion previa a su incorporacion en las etapas sucesivas del proceso.	6	71
72	Las materias primas conservadas por congelacion que requieren ser descongeladas previo al uso, se descogelan a una velocidad controlada para evitar el desarrollo de microorganismos y no son recongeladas. Ademas, se manipulan de manera que se minimiza la contaminacion proveniente de otras fuentes.	6	72
73	Las materias primas e insumos se almacenan en sitios exclusivos y adecuados que evitan su contaminacion y alteracion.	6	73
74	Los alimentos que por su naturaleza permiten un rapido crecimiento de microorganismos indeseables, se mantienen en condiciones que eviten su proliferacion. - Alimentos a temperaturas de refrigeracion no mayores a 4°C/2ºC. - Alimento en estado congelado (-18 °C). - Alimento caliente a temperaturas mayores de 60°C (140°F).	6	74
105	En la carpeta PAE se encuentra el formato CARACTERISTICAS DE CALIDAD, COMPRA DE ALIMENTOS Y ELEMENTOS DE ASEO, donde se relacionan los alimentos e insumos entregados por el operador, debidamente diligenciado y legible.	14	105
106	En la carpeta PAE se encuentra el documento de inventario de equipo y menaje debidamente diligenciado y firmado.	14	106
75	Las operaciones de fabricacion se realizan en forma secuencial y continua para que no se produzcan retrasos indebidos que permitan el crecimiento de microorganismos, contribuyan a otros tipos de deterioro o contaminacion del alimento. Cuando se requiera esperar entre una etapa del proceso y la siguiente, el alimento se mantiene protegido y en el caso de alimentos susceptibles al rapido crecimiento de microorganismos durante el tiempo de espera, se emplean temperaturas altas (> 60°C) o bajas no mayores de 4°C +/-2ºC segun sea el caso.	7	75
76	Los procedimientos de manufactura, tales como, lavar, pelar, cortar, clasificar, desmenuzar, extraer, batir, secar, entre otros, se realizan de manera que se protegen los alimentos y las materias primas de la contaminacion.	7	76
77	Durante las operaciones de fabricacion, almacenamiento y distribucion se toman medidas eficaces para evitar la contaminacion de los alimentos por contacto directo o indirecto con materias primas que se encuentren en las fases iniciales del proceso.	8	77
78	Las operaciones de fabricacion se realizan en forma secuencial y continua para evitar el cruce de flujos de produccion.	8	78
79	Todo equipo y utensilio que entra en contacto con materias primas o con material contaminado se limpia y se desinfecta cuidadosamente antes de ser utilizado nuevamente.	8	79
80	En la recepcion de materias primas e insumos, se aplican los criterios de aceptacion, liberacion, retencion o rechazo.	9	80
81	En la carpeta PAE se encuentra el Plan de Saneamiento establecido por la entidad territorial para la vigencia (programa de limpieza y desinfeccion, manejo de residuos, abastecimiento o suministro de agua y control integrado de plagas) con procedimientos escritos y registros de las actividades.	10	81
82	El operador entrega los implementos de aseo minimos segun lo establecido anexos tecnicos (mayoritaria /indigena) y se realiza su reposicion en caso de que aplique.	10	82
83	El operador entrega los insumos de aseo mensual para el comedor escolar, segun lo establecido en anexos tecnicos (mayoritaria /indigena) y se realiza su reposicion en caso que aplique.	10	83
84	Se lleva control de primeras entradas y primeras salidas a diario, con el fin de garantizar la rotacion de los productos (formato kardex).	11	84
85	El almacenamiento de materia prima e insumos, se realiza ordenadamente en pilas o estibas con separacion minima de 60 centimetros con respecto a las paredes perimetrales, y dispone de estibas o tarimas limpias y en buen estado, elevadas del piso por lo menos 15 centimetros de manera que permita la inspeccion, limpieza y fumigacion, si es el caso.	11	85
86	En el lugar o espacio destinado al almacenamiento de materia prima e insumos, no se realizan actividades diferentes.	11	86
87	Los plaguicidas, detergentes, desinfectantes y otras sustancias peligrosas, se encuentran debidamente rotuladas, incluida informacion sobre su modo de empleo y toxicidad, estos productos se almacenan en areas independientes con separacion fisica y su manipulacion solo es realizada por personal idoneo. Estas areas estan debidamente identificadas, organizadas, señalizadas y aireadas.	11	87
88	El transporte de materias primas, insumos y producto terminado (CCT) se realiza en condiciones que impiden la contaminacion, la proliferacion de microorganismos y eviten su alteracion, incluidos los daños en el envase o embalaje segun sea el caso.	12	88
89	Las materias primas que por su naturaleza requieran mantenerse refrigeradas o congeladas, son transportadas y distribuidas en condiciones que aseguran y garantizan su calidad  e inocuidad hasta su destino final. Este procedimiento es suceptible de verificacion mediante planiillas de registro de temperatura del vehiculo, durante el transporte, cargue o descargue del alimento.	12	89
90	Los vehiculos de transporte de alimentos, estan diseñados en material sanitario en su interior y aquellos que poseen sistema de refrigeracion o congelacion, cuentan con indicador de temperatura y su funcionamiento garantiza la conservacion de los alimentos.	12	90
91	Los contenedores o recipientes en los que se transportan los alimentos o materias primas, estan fabricados en materiales sanitarios que facilitan su correcta limpieza y desinfeccion.	12	91
92	Se dispone de recipientes, canastillas o elementos, de material sanitario, que aislen el producto de toda posibilidad de contaminacion que pueda presentarse por contacto directo del alimento con el piso del vehiculo.	12	92
93	No se transporta conjuntamente en un mismo vehiculo alimentos o materias primas con sustancias peligrosas u otras sustancias que por su naturaleza representen riesgo de contaminacion para el alimento o la materia prima.	12	93
94	Los vehiculos en los que se transportan los alimentos o materias primas, llevan en su exterior de forma claramente visible la leyenda: Transporte de Alimentos.	12	94
95	Los vehiculos destinados al transporte de alimentos y materias primas, cumplen dentro del territorio colombiano con los requisitos sanitarios que garantizan la adecuada proteccion y conservacion de los mismos.	12	95
99	Se suministra el complemento en el horario establecido. En caso que se presente modificacion en el horario de servido, se encuentra definido de manera escrita mediante acta de reunion del CAE.	13	99
100	El operador hace entrega de las materias primas e insumos, dentro del horario de la jornada escolar o por fuera del horario establecido, siempre y cuando no ponga en riesgo la calidad e inocuidad de las materias primas e insumos, ni la entrega oportuna del complemento alimentario.	13	100
101	Se promueven los buenos habitos con los estudiantes como lo es el lavado de manos con jabon desinfectante antes del consumo de los alimentos.	13	101
102	Existen avisos de señalizacion de areas ubicados en sitios estrategicos y en buen estado (verificar que sea del contrato vigente). Los avisos son: Area de recibo de alimentos - Area de almacenamiento - Area de preparacion - Area de distribucion - Comedor - Area de lavado - Avisos referentes a la necesidad de lavarse las manos luego de usar los servicios sanitarios.	14	102
103	El operador entrega remision de materias primas e insumos (la cual debe contener como minimo: Nombre de la sede educativa, numero de cupos adjudicados y atendidos, la modalidad de atencion, los dias de atencion para los cuales se estan entregando los viveres, tipo de alimentos, unidad de medida, cantidad de entrega y espacio de observaciones), firmada por el personal manipulador de alimentos que recibe y existe copia de este documento en el comedor escolar.	14	103
104	DEVOLUCIONES O FALTANTES: Se hace reposicion de materias primas o insumos faltantes, antes de la preparacion o entrega del alimento, de acuerdo con lo planeado en el ciclo de menu y el horario de servido estipulado, haciendo uso del formato establecido por la ETC, denominado “Reposicion y faltantes de alimentos”, debidamente diligenciado y firmado por el personal manipulador de alimentos y un representante de la unidad de servicio, que certifique la entrega.	14	104
107	El comedor escolar tiene publicado en un lugar visible la FICHA TECNICA de informacion del PAE, completamente diligenciada, incluidos los mecanismos que el operador y la ETC, tienen para atender las SPQR en el comedor escolar, de acuerdo con lo establecido por el MEN.	14	107
108	Se cuenta con la carpeta del Programa de Alimentacion Escolar, organizada y debidamente identificada, con soportes de los programas implementados, informacion del personal manipulador (hoja de vida, certificado de BPM), gestiones realizadas y registros de la ejecucion del programa en el comedor escolar.	14	108
109	En el comedor escolar está conformado el comité de alimentación escolar (CAE), y en la carpeta PAE reposa copia del acta de constitución CAE. Cuentan con actas de reunión del comité que evidencien su implementación.	14	109
110	Se diligencia diariamente, sin interrupciones el formato registro y control de asistencia de titulares de derecho, beneficiarios del programa, sin tachones o enmendaduras.	15	110
111	Verificacion de titulares atendiendos en el comedor Escolar donde la respuesta sea seleccionable, donde 1 cumple prcualmente 2 cumple 0 no cumple N/A no aplica y N/O no observado	15	111
112	Se suministra el complemento en el horario establecido. En caso que se presente modificacion en el horario de servido, se encuentra definido de manera escrita mediante acta de reunion del CAE.	13	112
113	El operador hace entrega de las materias primas e insumos, dentro del horario de la jornada escolar o por fuera del horario establecido, siempre y cuando no ponga en riesgo la calidad e inocuidad de las materias primas e insumos, ni la entrega oportuna del complemento alimentario.	13	113
114	Se promueven los buenos habitos con los estudiantes como lo es el lavado de manos con jabon desinfectante antes del consumo de los alimentos.	13	114
115	Los equipos se encuentran instalados y ubicados segun la secuencia logica del proceso tecnologico, desde la recepcion de las materias primas y demas insumos, hasta el envasado y embalaje del producto terminado.	3	115
116	La distancia entre los equipos y las paredes perimetrales, columnas u otros elementos de la edificacion, permite el funcionamiento de los equipos y facilita el acceso para la inspeccion, mantenimiento, limpieza y desinfeccion.	3	116
\.


--
-- Data for Name: instituciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instituciones (id, nombre, dane, municipio_id) FROM stdin;
29	Centro Educativo Cortaderas	119000000001	2
30	Centro Educativo La Honda	119000000002	2
31	Centro Educativo La Tarabita	119000000003	2
32	Institucion Educativa El Tablon	119000000004	2
33	Institucion Educativa La Herradura	119000000005	2
34	Institucion Educativa Llacuanas	119000000006	2
35	Institucion Educativa Normal Superior Santa Clara	119000000007	2
36	Institucion Educativa San Luis	119000000008	2
37	Institucion Educativa Santa Maria De Caquiona	119000000009	2
38	Centro Educativo Betania	119000000010	3
39	Centro Educativo Jose Maria Cordoba	119000000011	3
40	Centro Educativo La Leona	119000000012	3
41	Centro Educativo La Playa	119000000013	3
42	Centro Educativo La Primavera	119000000014	3
43	Centro Educativo Los Picos	119000000015	3
44	Centro Educativo Mirolindo	119000000016	3
45	Centro Educativo Pambilal	119000000017	3
46	Centro Educativo San Juan De La Florida	119000000018	3
47	Centro Educativo San Juan De La Guadua	119000000019	3
48	Institucion Educativa Agricola De Argelia	119000000020	3
49	Institucion Educativa Botafogo	119000000021	3
50	Institucion Educativa El Diviso	119000000022	3
51	Institucion Educativa La Belleza	119000000023	3
52	Institucion Educativa Marco Fidel Narvaez	119000000024	3
53	Institucion Educativa Puerto Rico	119000000025	3
54	Institucion Educativa Sinai	119000000026	3
55	Institucion Educativa Tecnica Miguel Zapata	119000000027	3
56	Centro Educativo Bermeja Alta	119000000028	4
57	Centro Educativo Buenos Aires	119000000029	4
58	Centro Educativo Cabuyo Bajo	119000000030	4
59	Centro Educativo Campo Bello Alto	119000000031	4
60	Centro Educativo Campo Bello Bajo	119000000032	4
61	Centro Educativo La Cabaña	119000000033	4
62	Centro Educativo La Lomita	119000000034	4
63	Centro Educativo La Palma	119000000035	4
64	Centro Educativo Los Andes	119000000036	4
65	Centro Educativo Sanabria	119000000037	4
66	Institucion Educativa Agricola San Alfonso	119000000038	4
67	Institucion Educativa La Planada	119000000039	4
68	Institucion Educativa Olaya	119000000040	4
69	Institucion Educativa Pureto	119000000041	4
70	Institucion Educativa Tecnica En Sistemas La Bermeja	119000000042	4
71	Institucion Educativa Vasco Nuñez De Balboa	119000000043	4
72	Centro Educativo Alto Llano	119000000044	5
73	Centro Educativo El Guadual	119000000045	5
74	Centro Educativo El Sesteadero	119000000046	5
75	Centro Educativo El Tambo	119000000047	5
76	Centro Educativo La Cueva	119000000048	5
77	Centro Educativo La Medina	119000000049	5
78	Centro Educativo Las Dantas	119000000050	5
79	Centro Educativo Los Rastrojos	119000000051	5
80	Centro Educativo Placetillas	119000000052	5
81	Centro Educativo Playa De San Juan	119000000053	5
82	Centro Educativo San Antonio Del Silencio	119000000054	5
83	Centro Educativo San Miguel	119000000055	5
84	Centro Educativo Santa Ana	119000000056	5
85	Centro Educativo Yunguillas	119000000057	5
86	Institucion Educativa Agropecuaria Alejandro Gomez Muñoz	119000000058	5
87	Institucion Educativa Agropecuaria Jose Dolores Daza	119000000059	5
88	Institucion Educativa Agropecuario Nuestra Señora Del Carmen	119000000060	5
89	Institucion Educativa Andino San Lorenzo	119000000061	5
90	Institucion Educativa El Carmen	119000000062	5
91	Institucion Educativa El Rodeo	119000000063	5
92	Institucion Educativa La Carbonera	119000000064	5
93	Institucion Educativa Marco Fidel Suarez	119000000065	5
94	Institucion Educativa San Fernando De Melchor	119000000066	5
95	Institucion Educativa San Jose Del Morro	119000000067	5
96	Institucion Educativa Santa Catalina De Laboure	119000000068	5
97	Institucion Educativa Tecnica Agropecuaria Nuestra Señora De Los Remedios	119000000069	5
98	Institucion Educativa Tecnico Domingo Belisario Gomez	119000000070	5
99	Centro Educativo Cascajero	119000000071	6
100	Centro Educativo Dos Rios	119000000072	6
101	Centro Educativo La Esmeralda	119000000073	6
102	Centro Educativo La Union - Llanito	119000000074	6
103	Centro Educativo Pisapasito	119000000075	6
104	Centro Educativo Santa Clara	119000000076	6
105	Institucion Educativa Agroambiental La Nueva Esperanza	119000000077	6
106	Institucion Educativa Agroambiental Nueva Vision Alto Naya	119000000078	6
107	Institucion Educativa Agroindustrial Valentin Carabali	119000000079	6
108	Institucion Educativa Agropecuaria Brisas De Mary Lopez	119000000080	6
109	Institucion Educativa Agropecuario Palo Blanco	119000000081	6
110	Institucion Educativa Cerro Catalina	119000000082	6
111	Institucion Educativa El Porvenir	119000000083	6
112	Institucion Educativa Maria Auxiliadora	119000000084	6
113	Institucion Educativa Mazamorrero	119000000085	6
114	Institucion Educativa Munchique	119000000086	6
115	Institucion Educativa Nueva Vision De Honduras	119000000087	6
116	Institucion Educativa Para El Desarrollo Intercultural De Las Comunidades Inedic	119000000088	6
117	Institucion Educativa Timba	119000000089	6
118	Centro Educativo Buenavista	119000000090	7
119	Centro Educativo Cacahual	119000000091	7
120	Centro Educativo Cenegueta	119000000092	7
121	Centro Educativo Chaux	119000000093	7
122	Centro Educativo Guangubio	119000000094	7
123	Centro Educativo La Arroyuela	119000000095	7
124	Centro Educativo La Aurelia	119000000096	7
125	Centro Educativo La Cohetera	119000000097	7
126	Centro Educativo La Selva	119000000098	7
127	Centro Educativo Puente Alto	119000000099	7
128	Centro Educativo San Gabriel	119000000100	7
129	I.E De Los Reasentamientos Del Cauca Kwe´Sx Ksxa´W Üusa´S Fxitxsa Yat (Despertar De Nuestros Sueños)	119000000101	7
130	I.E.Dptal Indg Misak Misak Ala Kusreinuk Minga Educativa Intercultural Kurak Chak	119000000102	7
131	Institucion Educativa Agropecuaria Nuestra Señora Del Carmen	119000000103	7
132	Institucion Educativa Agropecuaria Nuestra Señora Del Rosario	119000000104	7
133	Institucion Educativa Agropecuario La Capilla	119000000105	7
134	Institucion Educativa Alto Mojibio	119000000106	7
135	Institucion Educativa Carmen De Quintana	119000000107	7
136	Institucion Educativa Casas Bajas	119000000108	7
137	Institucion Educativa Dinde	119000000109	7
138	Institucion Educativa Efrain Orozco	119000000110	7
139	Institucion Educativa El Recuerdo Bajo	119000000111	7
140	Institucion Educativa El Tunel	119000000112	7
141	Institucion Educativa La Laguna Dinde	119000000113	7
142	Institucion Educativa La Meseta	119000000114	7
143	Institucion Educativa La Viuda	119000000115	7
144	Institucion Educativa Nuestra Señora De Las Mercedes	119000000116	7
145	Institucion Educativa Ortega	119000000117	7
146	Institucion Educativa San Antonio	119000000118	7
147	Centro Educativo Campo Alegre	119000000119	8
148	Centro Educativo El Cabuyal	119000000120	8
149	Centro Educativo El Pital	119000000121	8
150	Centro Educativo La Laguna	119000000122	8
151	I.E. Instituto Educativo De Formacion Intercultural Comunitario Kwesx Uma Kiwe - Infikuk	119000000123	8
152	Institucion Educativa Agroindustrial Monterilla	119000000124	8
153	Institucion Educativa El Rosario	119000000125	8
154	Institucion Educativa Empresarial Cerro Alto	119000000126	8
155	Institucion Educativa Guillermo Leon Valencia	119000000127	8
156	Institucion Educativa Los Comuneros	119000000128	8
157	Institucion Educativa Susana Trochez De Vivas	119000000129	8
158	Institucion Educativa Tecnica Agroambiental Intercultural Misak Shur Pupen	119000000130	8
159	Centro Educativo Rural Mixta Integrada Arrayan Chocho	119000000131	9
160	Institucion Educativa Agro Empresarial Huasano	119000000132	9
161	Institucion Educativa Agropecuaria Etnoeducativa El Credo	119000000133	9
162	Institucion Educativa Bilingue Dxi Paden	119000000134	9
163	Institucion Educativa Comercial El Palo	119000000135	9
164	Institucion Educativa Escipion Jaramillo	119000000136	9
165	Institucion Educativa Etnoeducativo De Toez	119000000137	9
166	Institucion Educativa La Niña Maria - Crucero De Guali	119000000138	9
167	Institucion Educativa Nucleo Escolar Rural Caloto	119000000139	9
168	Institucion Educativa Rural Integrada Quintero	119000000140	9
169	Institucion Educativa Sagrada Familia	119000000141	9
170	Institucion Educativa Tecnica Indigena Renacer	119000000142	9
171	Centro Educativo Alto De Puelenje	119000000143	10
173	Centro Educativo La Cominera	119000000145	10
174	Centro Educativo La Cosecha	119000000146	10
177	Centro Educativo San Rafael	119000000149	10
178	Institucion Educativa Agropecuario Carrizales	119000000150	10
179	Institucion Educativa Carmelo	119000000151	10
180	Institucion Educativa El Jagual	119000000152	10
181	Institucion Educativa El Pedregal	119000000153	10
182	Institucion Educativa El Tierrero	119000000154	10
183	Institucion Educativa Gabriel Garcia Marquez	119000000155	10
184	Institucion Educativa Jose Maria Obando	119000000156	10
185	Institucion Educativa La Capilla	119000000157	10
186	Institucion Educativa Paez	119000000158	10
187	Institucion Educativa San Jose	119000000159	10
188	Institucion Educativa Simon Bolivar	119000000160	10
189	Institucion Educativa Tecnica Agropecuaria Y De Sistemas De Corinto	119000000161	10
190	Institucion Educativa Villa De Las Palmas	119000000162	10
191	Centro Educativo San Antonio	119000000163	11
192	Centro Educativo Uribe	119000000164	11
193	Institucion Educativa Agroambiental La Cuchilla	119000000165	11
194	Institucion Educativa Agropecuario De Chisquio	119000000166	11
195	Institucion Educativa Agropecuario El Placer	119000000167	11
196	Institucion Educativa Agropecuario Fondas	119000000168	11
197	Institucion Educativa Agropecuario La Paz	119000000169	11
198	Institucion Educativa Agropecuario Y Ambiental Quilcase	119000000170	11
199	Institucion Educativa Antonio Jose De Sucre	119000000171	11
200	Institucion Educativa Carlos Alban	119000000172	11
201	Institucion Educativa Don Alfonso	119000000173	11
202	Institucion Educativa El Crucero De Pandiguando	119000000174	11
203	Institucion Educativa El Crucero Del Tambo	119000000175	11
204	Institucion Educativa El Rosal	119000000176	11
207	Institucion Educativa Los Anayes	119000000179	11
208	Institucion Educativa Pandiguando	119000000180	11
209	Institucion Educativa Piagua	119000000181	11
210	Institucion Educativa San Joaquin	119000000182	11
211	Institucion Educativa Silvano Caicedo Girio	119000000183	11
212	Institucion Educativa Tecnica De Huisito	119000000184	11
213	Institucion Educativa Tecnologica Agroambiental Y Etnoeducativa El Mango	119000000185	11
214	Institucion Educativa Veinte De Julio	119000000186	11
215	Institucion Educativa Victoria	119000000187	11
216	Institucion Educativa Agropecuario San Miguel	119000000188	12
217	Institucion Educativa San Francisco De Asis	119000000189	12
218	Institucion Educativa San Jose De Paletara	119000000190	12
220	Institucion Educativa La Cabaña	119000000192	\N
221	Institucion Educativa La Teta	119000000193	\N
223	Institución Educativa Jorge Eliecer Gaitan	119000000195	\N
224	Institución Educativa Niño Jesus De Praga	119000000196	\N
225	Centro Educativo San Jose	119000000197	14
226	Cetro Educativo El Carmen	119000000198	14
227	I. E. Agroecologica Del Pacifico Sur	119000000199	14
228	Institucion Educativa Etnica San Antonio De Napi	119000000200	14
229	Institucion Educativa Etnica San Jose	119000000201	14
230	Institucion Educativa Etnico Agroambiental San Pedro	119000000202	14
231	Institucion Educativa Normal Superior La Inmaculada	119000000203	14
232	Institucion Educativa San Pablo	119000000204	14
233	Institucion Educativa Santa Catalina	119000000205	14
234	Institución Educativa San Pedro Y San Pablo	119000000206	14
235	Institución Educativa Santo Domingo Savio	119000000207	14
237	Centro Educativo El Retiro	119000000209	\N
238	Centro Educativo La Milagrosa	119000000210	\N
239	Institucion Educativa Agroindustrial La Florida	119000000211	\N
240	Institucion Educativa Agropecuario Belen	119000000212	\N
241	Institucion Educativa Agropecuario El Carmen	119000000213	\N
242	Institucion Educativa Agropecuario El Meson	119000000214	\N
243	Institucion Educativa Agropecuario La Palmera	119000000215	\N
244	Institucion Educativa Agropecuario San Andres	119000000216	\N
245	Institucion Educativa Bilingue Intercultural Nu´S Wesx Uma Kiwe	119000000217	\N
247	Institucion Educativa Guanacas	119000000219	\N
248	Institucion Educativa Internado Escolar Rural Indigena Ya´Th Fxi´Znxi	119000000220	\N
249	Institucion Educativa La Jigua	119000000221	\N
250	Institucion Educativa Pedregal	119000000222	\N
251	Institucion Educativa Rio Sucio	119000000223	\N
252	Institucion Educativa Salado Blanco	119000000224	\N
254	Institucion Educativa Santa Helena	119000000226	\N
255	Institucion Educativa Santa Rita	119000000227	\N
256	Institucion Educativa Tecnica Agropecuaria Y Ambiental De Turmina	119000000228	\N
257	Institucion Educativa Tecnica Francisco Jose De Caldas	119000000229	\N
258	Institucion Educativa Tecnica Y Academica San Vicente De Paul	119000000230	\N
259	Institucion Educativa Tumbichucue	119000000231	\N
260	Institucion Educativa Valentin Garcia	119000000232	\N
261	Institucion Educativa Bilingue Intercultural Thutan Wesx	119000000233	\N
262	Institucion Educativa Bilingue Intercultural U´Y Scue	119000000234	\N
263	Institucion Educativa Bilingue Kwe´Sx Yu´Kiwe	119000000235	\N
264	Institucion Educativa Bilingüe Intercultural Sek Buy	119000000236	\N
265	Institucion Educativa De Promocion Social Bilingue Intercultural	119000000237	\N
266	Institucion Educativa Indigena Bilingue Intercultural El Tablazo	119000000238	\N
267	Institucion Educativa Marden Arnulfo Betancour	119000000239	\N
268	Institucion Educativa Y Residencial Bilingüe Intercultural	119000000240	\N
269	Institución Educativa Bilingüe Intercultural Kwe Sx Nasa Ksxa Wnxi	119000000241	\N
271	Institucion Educativa Agropecuaria La Cuchilla	119000000243	17
273	Institucion Educativa El Pindio	119000000245	17
274	Institucion Educativa Francisco De Paula Santander	119000000246	17
275	Centro Educativo El Diviso	119000000247	18
276	Centro Educativo El Roble	119000000248	18
277	Centro Educativo La Florida	119000000249	18
278	Centro Educativo Santa Rita	119000000250	18
279	Institucion Educativa Agropecuaria El Palmar	119000000251	18
280	Institucion Educativa Agropecuaria Santa Juana	119000000252	18
281	Institucion Educativa Arbelaez	119000000253	18
283	Institucion Educativa Francisco Jose De Caldas	119000000255	18
284	Institucion Educativa Los Uvos	119000000256	18
285	Institucion Educativa Mardoqueo Muñoz	119000000257	18
286	Institucion Educativa Normal Superior Los Andes	119000000258	18
287	Institucion Educativa Promocion Social	119000000259	18
288	Institucion Educativa San Vicente	119000000260	18
290	Institucion Educativa Tecnica Agroindustrial El Recreo	119000000262	18
291	C.E. Chichiguara	119000000263	19
292	Centro Educativo San Antonio De Chuare	119000000264	19
293	Institucion Educativa Agropecuaria Del Micay	119000000265	19
294	Institucion Educativa Del Pacifico	119000000266	19
295	Institucion Educativa Etnoeducativo Sagrado Corazon De Jesus	119000000267	19
296	Institucion Educativa Etnoeducativo San Francisco De Joli	119000000268	19
297	Institucion Educativa San Antonio De Potedo	119000000269	19
298	Institucion Educativa Santa Cruz De El Baco	119000000270	19
299	Institucion Educativa Tecnico Agroambiental Santa Maria	119000000271	19
300	Institucion Etnoeducativa El Playon	119000000272	19
301	C.E. El Naranjal	119000000273	20
302	C.E. La Bermeja	119000000274	20
303	Centro Educativo Carbonera Baja	119000000275	20
304	Centro Educativo Curacas	119000000276	20
305	Centro Educativo Damasco	119000000277	20
306	Centro Educativo El Paraiso	119000000278	20
307	Centro Educativo El Pilamo	119000000279	20
309	Centro Educativo Florencia	119000000281	20
310	Centro Educativo La Calera	119000000282	20
311	Centro Educativo La Despensa	119000000283	20
312	Centro Educativo Los Llanos	119000000284	20
313	Centro Educativo Mojarras	119000000285	20
314	Centro Educativo San Juan	119000000286	20
315	Centro Educativo San Roque	119000000287	20
316	Institucion Educativa Agropecuaria De Esmeraldas	119000000288	20
317	Institucion Educativa Agropecuaria De La Bermeja	119000000289	20
318	Institucion Educativa Agropecuaria San Joaquin	119000000290	20
319	Institucion Educativa Agropecuaria Y Minera La Despensa	119000000291	20
320	Institucion Educativa Arboleda	119000000292	20
321	Institucion Educativa Buenos Aires	119000000293	20
322	Institucion Educativa Carbonera	119000000294	20
323	Institucion Educativa Cerro Lindo	119000000295	20
324	Institucion Educativa De Mercaderes	119000000296	20
325	Institucion Educativa De Mojarras	119000000297	20
326	Institucion Educativa El Caney	119000000298	20
328	Institucion Educativa Genaro Leon	119000000300	20
329	Institucion Educativa Las Juntas	119000000301	20
330	Institucion Educativa Lourdes	119000000302	20
332	Institucion Educativa Nuestra Señora De La Candelaria	119000000304	20
334	Institucion Educativa San Juan	119000000306	20
335	Institucion Educativa Santa Maria	119000000307	20
336	Institucion Educativa Tecnica Agropecuaria De Mercaderes	119000000308	20
337	I. E. Agroecologica Amazónica De San Juan De Villalobos	119000000309	21
338	I.E. Corregimiento El Ortigal	119000000310	21
339	Institucion Educativa Agroindustrial De La Cabecera De Santa Ana	119000000311	21
340	Institucion Educativa Atanasio Girardot	119000000312	21
341	Institucion Educativa El Caraqueño	119000000313	21
342	Institucion Educativa El Recreo	119000000314	21
344	Institucion Educativa La Munda	119000000316	21
345	Institucion Educativa Libardo Mejia	119000000317	21
346	Institucion Educativa Los Andes	119000000318	21
347	Institucion Educativa Nuevo Amanecer	119000000319	21
348	Institucion Educativa Ricardo Nieto	119000000320	21
349	Institucion Educativa Santa Ana	119000000321	21
350	Institución Educativa Tecnico Mariscal Sucre	119000000322	21
353	Centro Educativo El Rosario	119000000325	22
354	Centro Educativo La Estacion	119000000326	22
355	Centro Educativo La Union	119000000327	22
357	I.E. El Meson	119000000329	22
358	Institucion Educativa Agua Negra	119000000330	22
359	Institucion Educativa Agropecuaria Gabriel Ceron	119000000331	22
360	Institucion Educativa Carpintero	119000000332	22
361	Institucion Educativa Chimborazo	119000000333	22
362	Institucion Educativa El Libano	119000000334	22
364	Institucion Educativa La Toma	119000000336	22
365	Institucion Educativa Las Velas	119000000337	22
366	Institucion Educativa Mi Bohio	119000000338	22
368	Institucion Educativa San Isidro	119000000340	22
369	Institucion Educativa Santa Rosa De Pescador	119000000341	22
371	Institucion Educativa Tecnica Francisco Antonio Rada	119000000343	22
372	Institucion Educativa Agroempresarial La Esmeralda	119000000344	23
373	Institucion Educativa Almirante Padilla	119000000345	23
374	Institucion Educativa El Tetillo	119000000346	23
375	Institucion Educativa Indigena El Pilamo	119000000347	23
376	Institucion Educativa Tecnica Agroindustrial El Pilamo	119000000348	23
377	Institucion Educativa Yurumangui	119000000349	23
378	Institucion Educativa Agropecuaria Avirama	119000000350	24
379	Institucion Educativa Bilingue Intercultural Licona	119000000351	24
380	Institucion Educativa Bilingue Intercultural San Jose	119000000352	24
381	Institucion Educativa Bilingue Sol De Los Andes	119000000353	24
382	Institucion Educativa Bilingue U´Y Kiwe	119000000354	24
383	Institucion Educativa Del Corregimiento De Coqueto	119000000355	24
384	Institucion Educativa Del Corregimiento De Rio Chiquito	119000000356	24
385	Institucion Educativa Del Corregimiento De San Luis	119000000357	24
386	Institucion Educativa Indigena El Pizno	119000000358	24
387	Institucion Educativa Indigena La Union	119000000359	24
388	Institucion Educativa Indigena Lame De Togoima	119000000360	24
389	Institucion Educativa Indigena Simon Bolivar	119000000361	24
390	Institucion Educativa Internado De San Jose	119000000362	24
391	Institucion Educativa Nasa Cxhab De Gualanday	119000000363	24
392	Institucion Educativa San Miguel De Vitonco	119000000364	24
393	Institucion Educativa Santo Domingo Savio	119000000365	24
394	Institucion Educativa Tecnica Agroempresarial El Pedregal	119000000366	24
395	Institucion Educativa Tecnica Agroindustrial De Itaibe	119000000367	24
396	Institucion Educativa Tecnica Comercial E Industrial De Belalcazar	119000000368	24
397	Institucion Educativa Tecnica De Wila	119000000369	24
398	Institucion Educativa Tecnica Juan Tama	119000000370	24
399	Institucion Educativa Tecnica Montecruz	119000000371	24
400	Institucion Educativa Tecnica Ricaurte	119000000372	24
401	Institucion Educativa Tecnica Y Agroambiental De Talaga	119000000373	24
402	Institucion Educativa Tecnico Agropecuario Indigena De Mosoco	119000000374	24
403	Institucion Educativa Yu´Luucx Tacuesco Cxhab Wala	119000000375	24
404	C.E. El Guayabal	119000000376	25
405	C.E. La Florida	119000000377	25
406	Centro Educativo Brisas	119000000378	25
407	Centro Educativo Cefiro	119000000379	25
408	Centro Educativo El Bordo	119000000380	25
409	Centro Educativo El Estrecho	119000000381	25
410	Centro Educativo El Naranjo	119000000382	25
411	Centro Educativo El Patanguejo	119000000383	25
412	Centro Educativo El Placer	119000000384	25
413	Centro Educativo La Mesa	119000000385	25
414	Centro Educativo Pan De Azucar	119000000386	25
415	Centro Educativo Peñas Blancas	119000000387	25
416	Centro Educativo Piedra Sentada	119000000388	25
417	Centro Educativo Yarumal	119000000389	25
418	Institucion Educativa Agropecuaria Y Ambiental El Bordo	119000000390	25
420	Institucion Educativa Comercial Patia	119000000392	25
421	Institucion Educativa De Galindez	119000000393	25
422	Institucion Educativa De La Fonda	119000000394	25
423	Institucion Educativa De Patia	119000000395	25
424	Institucion Educativa De Sachacoco	119000000396	25
425	Institucion Educativa El Estrecho	119000000397	25
426	Institucion Educativa El Tuno	119000000398	25
427	Institucion Educativa La Fonda	119000000399	25
428	Institucion Educativa Las Tallas	119000000400	25
429	Institucion Educativa Pilamo	119000000401	25
430	Institucion Educativa Santa Cruz	119000000402	25
431	Institucion Educativa Santa Rosa Alta	119000000403	25
432	Institucion Educativa Tecnica Agropecuaria El Bordo	119000000404	25
433	Institucion Educativa Tecnico Agropecuario De Angulo	119000000405	25
434	Institucion Educativa Tecnico Ambiental De Don Alonso	119000000406	25
435	Institucion Educativa Tecnologico De Patia	119000000407	25
437	Institucion Educativa Piamonte	119000000409	26
438	Institucion Educativa Rural Mixta La Independencia	119000000410	26
439	Institucion Educativa San Jose De Fragua	119000000411	26
441	Centro Educativo El Boqueron	119000000413	27
442	Centro Educativo El Pinar	119000000414	27
443	Institucion Educativa Agropecuaria La Florida	119000000415	27
444	Institucion Educativa Agropecuaria Y Ambiental Fray Placido	119000000416	27
446	Institucion Educativa De Promocion Y Bienestar Social San Jose	119000000418	27
447	Institucion Educativa El Pescador	119000000419	27
449	Institucion Educativa Nueva Generacion	119000000421	27
450	Institucion Educativa Para El Emprendimiento El Progreso De Oriente	119000000422	27
452	Institucion Educativa Sebastian De Belalcazar	119000000424	27
453	Institucion Educativa Y Residencial El Hogar	119000000425	27
454	Institución Educativa El Arrayan	119000000426	27
455	Institución Educativa Madre De Dios	119000000427	27
456	I. E. Agroecologico El Hormiguero	119000000428	28
457	I. E. Fidelina Echeverri	119000000429	28
458	Institucion Educativa Jose Hilario Lopez	119000000430	28
459	Institucion Educativa Juan Jose Rondon	119000000431	28
460	Institucion Educativa La Balsa	119000000432	28
461	Institucion Educativa Sagrado Corazon De Jesus	119000000433	28
462	Institucion Educativa San Carlos	119000000434	28
464	Institucion Educativa Tecnico	119000000436	28
465	Institución Educativa San Pedro Claver	119000000437	28
466	I. E. Agropecuario San Isidro	119000000438	\N
467	Centro Educativo Divino Niño	119000000439	\N
468	Institucion Educativa Agroambiental Y Ecoturistica De Coconuco	119000000440	\N
469	Institucion Educativa Del Corregimiento De Paletara	119000000441	\N
470	Institucion Educativa Indigena Bilingue Intercultural San Antonio De La Laguna	119000000442	\N
471	Institucion Educativa Pio Xii	119000000443	\N
472	Institucion Educativa Promotora Ambiental Y Ecologica De Purace	119000000444	\N
473	Institucion Educativa San Juan De Villa-Lobo	119000000445	\N
475	Institucion Educativa Yanakuna	119000000447	\N
476	Centro Educativo Alto De La Cruz	119000000448	30
477	Centro Educativo Bellavista	119000000449	30
479	Centro Educativo El Jigual	119000000451	30
480	Centro Educativo Gualoto	119000000452	30
481	Institucion Educativa Alfonso Xii	119000000453	30
482	Institucion Educativa De La Cabecera	119000000454	30
483	Institucion Educativa Del Cestreo	119000000455	30
485	Institucion Educativa Pablo Vi	119000000457	30
486	Institucion Educativa Santa Teresita	119000000458	30
488	Centro Educativo El Rosal	119000000460	31
489	Centro Educativo Paramo De Barbillas	119000000461	31
490	Centro Educativo San Agustin	119000000462	31
491	Institucion Educativa De Mármato	119000000463	31
492	Institucion Educativa De Valencia	119000000464	31
493	Institucion Educativa Del Pueblo	119000000465	31
494	Institucion Educativa Del Macizo Colombiano	119000000466	31
495	Institucion Educativa Paramo De Letras	119000000467	31
496	Institucion Educativa Perez	119000000468	31
497	Institucion Educativa San Sebastian	119000000469	31
498	Institucion Educativa Santiago	119000000470	31
499	Centro Educativo Alto Bonito	119000000471	32
500	Centro Educativo La Vetulia	119000000472	32
501	Institucion Educativa Ana Josefa Morales Duque	119000000473	32
502	Institucion Educativa Bilingue El Progreso	119000000474	32
503	Institucion Educativa Bilingue La Union	119000000475	32
504	Institucion Educativa Cacique Calarca	119000000476	32
505	Institucion Educativa Chapa	119000000477	32
506	Institucion Educativa El Palmar	119000000478	32
507	Institucion Educativa Fernandez Guerra	119000000479	32
509	Institucion Educativa Institucion Tecnica	119000000481	32
510	Institucion Educativa La Inmaculada	119000000482	32
511	Institucion Educativa Limbania Velasco	119000000483	32
512	Institucion Educativa Los Pinos	119000000484	32
514	Institucion Educativa Mi Pequeño Mundo	119000000486	32
515	Institucion Educativa Nuestra Señora De Fatima	119000000487	32
516	Institucion Educativa Politecnico	119000000488	32
517	Institucion Educativa Rafael Tello	119000000489	32
518	Institucion Educativa San Antonio De La Union	119000000490	32
519	Institucion Educativa Tecnica Agropecuaria Y Forestal La Tolda	119000000491	32
\.


--
-- Data for Name: municipios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.municipios (id, nombre) FROM stdin;
1	POPAYAN
2	ALMAGUER
3	ARGELIA
4	BALBOA
5	BOLIVAR
6	BUENOS AIRES
7	CAJIBIO
8	CALDONO
9	CALOTO
10	CORINTO
11	EL TAMBO
12	FLORENCIA
13	GUACHENE
14	GUAPI
15	INZA
16	JAMBALO
17	LA SIERRA
18	LA VEGA
19	LOPEZ DE MICAY
20	MERCADERES
21	MIRANDA
22	MORALES
23	PADILLA
24	PAEZ
25	PATIA
26	PIAMONTE
27	PIENDAMO
28	PUERTO TEJADA
29	PURACE
30	ROSAS
31	SAN SEBASTIAN
32	SANTANDER DE QUILICHAO
33	SANTA ROSA
34	SILVIA
35	SOTARA
36	SUAREZ
37	SUCRE
38	TIMBIO
39	TIMBIQUI
40	TORIBIO
41	TOTORO
42	VILLA RICA
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre) FROM stdin;
1	Visitador
3	admin 
2	supervisor 
4	supervisor
\.


--
-- Data for Name: sedes_educativas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sedes_educativas (id, nombre_sede, dane, due, lat, lon, principal, municipio_id, institucion_id) FROM stdin;
3	Sede Test Chichiguara	123456789	987654321	2.4389	-76.6134	f	19	291
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nombre, correo, contrasena, rol_id) FROM stdin;
2	annny	ana@gmail.com	$2b$12$0jD8MvlzwT/iL7JorsdZXemZYcmgr1VRi0D.R9kfAsI3MiYURXiu.	1
3	anny	ana1@gmail.com	$2b$12$edohdY7t5i6GSqcVskD.HeULdE5OQ.A1K4XUnmI/cbU.mNZeQno9.	1
4	anny	ana11@gmail.com	$2b$12$O0zLuGRjIqP3a5S10Ck4ce6QMEeIhA9p5w9lGC15YBuusgLHbKiki	1
5	daniel	daniel@gmail.com	$2b$12$JBfDhCfDULLSIIbIyXyepOK/X.c/whWmPvgXE/NL6x928xQfh0Xi2	1
6	daniel	daaaaniel@gmail.com	$2b$12$Q2/29Sh2tESKYQcn6N4mSuu6MjxgzLiDRtIawqks5KJB3.PdNm8bW	1
7	daniel	dasaaaniel@gmail.com	$2b$12$dCc8sV3NOYZvUyDCQtIRROgc7vJM.sGSB39IngrfF0Bi6O.0cPInK	1
8	deyby	dey@gmail.com	$2b$12$f8H9ujhUdbO2Ci40LhOnXuXsc5oDYejwYCkMI3rqwEjbmM35QJgTe	1
10	supervisor test	test@supervisor.com	$2b$12$4netFzNrbUKtLtzH6qf6NuG0G/dpFwoiXyy.y6Oo.7.yu9PvvG3Uu	1
\.


--
-- Data for Name: visita_respuestas_completas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visita_respuestas_completas (id, visita_completa_id, item_id, respuesta, observacion) FROM stdin;
1	1	50	Cumple	\N
2	1	116	No Cumple	\N
3	1	115	Cumple Parcialmente	\N
4	1	111	Cumple	\N
5	1	110	No Cumple	\N
6	1	109	N/A	\N
7	1	108	No Cumple	\N
8	1	107	Cumple Parcialmente	\N
9	1	106	Cumple	\N
10	1	105	N/O	\N
11	1	104	No Cumple	\N
12	1	103	Cumple Parcialmente	\N
13	1	102	Cumple	\N
14	1	88	Cumple Parcialmente	\N
15	1	89	N/A	\N
16	1	93	Cumple	\N
17	1	95	N/A	\N
18	1	94	Cumple	\N
19	1	92	No Cumple	\N
20	1	91	Cumple Parcialmente	\N
21	1	90	Cumple Parcialmente	\N
\.


--
-- Data for Name: visitas_completas_pae; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visitas_completas_pae (id, fecha_visita, contrato, operador, caso_atencion_prioritaria, municipio_id, institucion_id, sede_id, profesional_id, fecha_creacion, estado, observaciones, foto_evidencia, video_evidencia, audio_evidencia, pdf_evidencia, foto_firma) FROM stdin;
1	2025-08-04 00:00:00	11111	111111	ACTA RAPIDA	19	291	3	9	2025-08-04 15:34:37.365499	completada	\N	\N	\N	\N	\N	\N
\.


--
-- Name: checklist_categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.checklist_categorias_id_seq', 15, true);


--
-- Name: checklist_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.checklist_items_id_seq', 116, true);


--
-- Name: instituciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.instituciones_id_seq', 521, true);


--
-- Name: municipios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.municipios_id_seq', 42, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 1, false);


--
-- Name: sedes_educativas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sedes_educativas_id_seq', 3, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 11, true);


--
-- Name: visita_respuestas_completas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visita_respuestas_completas_id_seq', 21, true);


--
-- Name: visitas_completas_pae_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visitas_completas_pae_id_seq', 1, true);


--
-- Name: checklist_categorias checklist_categorias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_categorias
    ADD CONSTRAINT checklist_categorias_nombre_key UNIQUE (nombre);


--
-- Name: checklist_categorias checklist_categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_categorias
    ADD CONSTRAINT checklist_categorias_pkey PRIMARY KEY (id);


--
-- Name: checklist_items checklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT checklist_items_pkey PRIMARY KEY (id);


--
-- Name: instituciones instituciones_dane_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instituciones
    ADD CONSTRAINT instituciones_dane_key UNIQUE (dane);


--
-- Name: instituciones instituciones_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instituciones
    ADD CONSTRAINT instituciones_nombre_key UNIQUE (nombre);


--
-- Name: instituciones instituciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instituciones
    ADD CONSTRAINT instituciones_pkey PRIMARY KEY (id);


--
-- Name: municipios municipios_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipios
    ADD CONSTRAINT municipios_nombre_key UNIQUE (nombre);


--
-- Name: municipios municipios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipios
    ADD CONSTRAINT municipios_pkey PRIMARY KEY (id);


--
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sedes_educativas sedes_educativas_dane_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_dane_key UNIQUE (dane);


--
-- Name: sedes_educativas sedes_educativas_due_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_due_key UNIQUE (due);


--
-- Name: sedes_educativas sedes_educativas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: visita_respuestas_completas visita_respuestas_completas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visita_respuestas_completas
    ADD CONSTRAINT visita_respuestas_completas_pkey PRIMARY KEY (id);


--
-- Name: visitas_completas_pae visitas_completas_pae_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae
    ADD CONSTRAINT visitas_completas_pae_pkey PRIMARY KEY (id);


--
-- Name: ix_instituciones_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_instituciones_id ON public.instituciones USING btree (id);


--
-- Name: ix_municipios_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_municipios_id ON public.municipios USING btree (id);


--
-- Name: ix_roles_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_roles_id ON public.roles USING btree (id);


--
-- Name: ix_sedes_educativas_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_sedes_educativas_id ON public.sedes_educativas USING btree (id);


--
-- Name: ix_usuarios_correo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_usuarios_correo ON public.usuarios USING btree (correo);


--
-- Name: ix_usuarios_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_usuarios_id ON public.usuarios USING btree (id);


--
-- Name: ix_visita_respuestas_completas_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visita_respuestas_completas_id ON public.visita_respuestas_completas USING btree (id);


--
-- Name: ix_visitas_completas_pae_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visitas_completas_pae_id ON public.visitas_completas_pae USING btree (id);


--
-- Name: checklist_items fk_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_items
    ADD CONSTRAINT fk_categoria FOREIGN KEY (categoria_id) REFERENCES public.checklist_categorias(id);


--
-- Name: instituciones fk_municipio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instituciones
    ADD CONSTRAINT fk_municipio FOREIGN KEY (municipio_id) REFERENCES public.municipios(id);


--
-- Name: sedes_educativas sedes_educativas_institucion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_institucion_id_fkey FOREIGN KEY (institucion_id) REFERENCES public.instituciones(id);


--
-- Name: sedes_educativas sedes_educativas_municipio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES public.municipios(id);


--
-- Name: usuarios usuarios_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- Name: visita_respuestas_completas visita_respuestas_completas_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visita_respuestas_completas
    ADD CONSTRAINT visita_respuestas_completas_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.checklist_items(id);


--
-- Name: visita_respuestas_completas visita_respuestas_completas_visita_completa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visita_respuestas_completas
    ADD CONSTRAINT visita_respuestas_completas_visita_completa_id_fkey FOREIGN KEY (visita_completa_id) REFERENCES public.visitas_completas_pae(id);


--
-- Name: visitas_completas_pae visitas_completas_pae_institucion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae
    ADD CONSTRAINT visitas_completas_pae_institucion_id_fkey FOREIGN KEY (institucion_id) REFERENCES public.instituciones(id);


--
-- Name: visitas_completas_pae visitas_completas_pae_municipio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae
    ADD CONSTRAINT visitas_completas_pae_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES public.municipios(id);


--
-- Name: visitas_completas_pae visitas_completas_pae_profesional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae
    ADD CONSTRAINT visitas_completas_pae_profesional_id_fkey FOREIGN KEY (profesional_id) REFERENCES public.usuarios(id);


--
-- Name: visitas_completas_pae visitas_completas_pae_sede_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas_completas_pae
    ADD CONSTRAINT visitas_completas_pae_sede_id_fkey FOREIGN KEY (sede_id) REFERENCES public.sedes_educativas(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

