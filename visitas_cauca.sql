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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: evidencias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evidencias (
    id integer NOT NULL,
    id_visita integer,
    tipo text,
    archivo_path text,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.evidencias OWNER TO postgres;

--
-- Name: evidencias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.evidencias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.evidencias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre text NOT NULL
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
    due character varying NOT NULL,
    institucion character varying NOT NULL,
    sede character varying NOT NULL,
    municipio character varying NOT NULL,
    dane character varying NOT NULL,
    lat double precision,
    lon double precision,
    nombre_sede text
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
    nombre text NOT NULL,
    correo text NOT NULL,
    "contrase¤a" text NOT NULL,
    rol text DEFAULT 'usuario'::text,
    id_rol integer
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
-- Name: visitas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visitas (
    id integer NOT NULL,
    sede_id integer NOT NULL,
    tipo_asunto text NOT NULL,
    foto_evidencia character varying,
    video_evidencia character varying,
    pdf_evidencia character varying,
    audio_evidencia character varying,
    foto_firma character varying,
    lat double precision,
    lon double precision,
    fecha date,
    responsable character varying,
    observaciones text,
    prioridad character varying,
    hora time without time zone,
    id_sede integer,
    asunto text,
    latitud real,
    longitud real,
    firma_path text
);


ALTER TABLE public.visitas OWNER TO postgres;

--
-- Name: visitas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visitas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visitas_id_seq OWNER TO postgres;

--
-- Name: visitas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visitas_id_seq OWNED BY public.visitas.id;


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
-- Name: visitas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas ALTER COLUMN id SET DEFAULT nextval('public.visitas_id_seq'::regclass);


--
-- Data for Name: evidencias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evidencias (id, id_visita, tipo, archivo_path, descripcion, fecha_subida) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre) FROM stdin;
\.


--
-- Data for Name: sedes_educativas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sedes_educativas (id, due, institucion, sede, municipio, dane, lat, lon, nombre_sede) FROM stdin;
1	DUE001	IE Agropecuaria	Sede Principal	Timbiquí	1234567890	2.7634	-77.4632	\N
2	DUE002	Colegio Pacífico	Sede Urbana	Guapi	2345678901	2.57	-77.8912	\N
3	DUE003	IE Técnica	Sede Rural	López de Micay	3456789012	2.6398	-77.5221	\N
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nombre, correo, "contrase¤a", rol, id_rol) FROM stdin;
\.


--
-- Data for Name: visitas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visitas (id, sede_id, tipo_asunto, foto_evidencia, video_evidencia, pdf_evidencia, audio_evidencia, foto_firma, lat, lon, fecha, responsable, observaciones, prioridad, hora, id_sede, asunto, latitud, longitud, firma_path) FROM stdin;
1	1	Revisión infraestructura	\N	\N	\N	\N	\N	2.7634	-77.4632	2025-06-25	Anny Díaz	Todo en orden	Alta	09:00:00	\N	\N	\N	\N	\N
2	1	Entrega de materiales	\N	\N	\N	\N	\N	2.7634	-77.4632	2025-06-25	Carlos Paz	Material incompleto	Media	10:30:00	\N	\N	\N	\N	\N
3	2	Reunión con docentes	\N	\N	\N	\N	\N	2.57	-77.8912	2025-06-25	María López	Docentes presentes	Baja	08:00:00	\N	\N	\N	\N	\N
4	2	Inspección sanitaria	\N	\N	\N	\N	\N	2.57	-77.8912	2025-06-25	Luis Ríos	Faltan lavamanos	Alta	11:00:00	\N	\N	\N	\N	\N
5	3	Actualización datos	\N	\N	\N	\N	\N	2.6398	-77.5221	2025-06-25	Jorge Mina	Faltan formularios	Media	13:45:00	\N	\N	\N	\N	\N
6	3	Supervisión de clase	\N	\N	\N	\N	\N	2.6398	-77.5221	2025-06-25	Lina Campo	Se recomienda seguimiento	Baja	07:30:00	\N	\N	\N	\N	\N
7	1	Revisión eléctrica	\N	\N	\N	\N	\N	2.7634	-77.4632	2025-06-25	Debyson Quiñones	Se detectaron fallas	Alta	14:15:00	\N	\N	\N	\N	\N
\.


--
-- Name: evidencias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.evidencias_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.usuarios_id_seq', 1, false);


--
-- Name: visitas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visitas_id_seq', 7, true);


--
-- Name: evidencias evidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evidencias
    ADD CONSTRAINT evidencias_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sedes_educativas sedes_educativas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes_educativas
    ADD CONSTRAINT sedes_educativas_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: visitas visitas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas
    ADD CONSTRAINT visitas_pkey PRIMARY KEY (id);


--
-- Name: ix_sedes_educativas_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_sedes_educativas_id ON public.sedes_educativas USING btree (id);


--
-- Name: ix_visitas_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visitas_id ON public.visitas USING btree (id);


--
-- Name: evidencias evidencias_id_visita_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evidencias
    ADD CONSTRAINT evidencias_id_visita_fkey FOREIGN KEY (id_visita) REFERENCES public.visitas(id);


--
-- Name: usuarios usuarios_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id);


--
-- Name: visitas visitas_sede_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitas
    ADD CONSTRAINT visitas_sede_id_fkey FOREIGN KEY (sede_id) REFERENCES public.sedes_educativas(id);


--
-- PostgreSQL database dump complete
--

