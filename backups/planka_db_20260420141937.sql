--
-- PostgreSQL database dump
--

\restrict qdZc8cTTgcA8JxRHB1kHhY0xeHfihNkVar0SWnbtD3YxpGcnRJ0KHt7NbMVOU2c

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: next_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.next_id(OUT id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
      DECLARE
        shard INT := 1;
        epoch BIGINT := 1567191600000;
        sequence BIGINT;
        milliseconds BIGINT;
      BEGIN
        SELECT nextval('next_id_seq') % 1024 INTO sequence;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO milliseconds;
        id := (milliseconds - epoch) << 23;
        id := id | (shard << 10);
        id := id | (sequence);
      END;
    $$;


ALTER FUNCTION public.next_id(OUT id bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.action (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint,
    type text NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    board_id bigint
);


ALTER TABLE public.action OWNER TO postgres;

--
-- Name: attachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attachment (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    creator_user_id bigint,
    type text NOT NULL,
    data jsonb NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.attachment OWNER TO postgres;

--
-- Name: background_image; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.background_image (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    uploaded_file_id text NOT NULL,
    extension text NOT NULL,
    size bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.background_image OWNER TO postgres;

--
-- Name: base_custom_field_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.base_custom_field_group (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.base_custom_field_group OWNER TO postgres;

--
-- Name: board; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.board (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    default_view text NOT NULL,
    default_card_type text NOT NULL,
    limit_card_types_to_default_one boolean NOT NULL,
    always_display_card_creator boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expand_task_lists_by_default boolean NOT NULL,
    display_card_ages boolean NOT NULL
);


ALTER TABLE public.board OWNER TO postgres;

--
-- Name: board_membership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.board_membership (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    board_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role text NOT NULL,
    can_comment boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.board_membership OWNER TO postgres;

--
-- Name: board_subscription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.board_subscription (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.board_subscription OWNER TO postgres;

--
-- Name: card; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.card (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint NOT NULL,
    list_id bigint NOT NULL,
    creator_user_id bigint,
    prev_list_id bigint,
    cover_attachment_id bigint,
    type text NOT NULL,
    "position" double precision,
    name text NOT NULL,
    description text,
    due_date timestamp without time zone,
    stopwatch jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    list_changed_at timestamp without time zone,
    comments_total integer NOT NULL,
    is_closed boolean NOT NULL,
    is_due_completed boolean
);


ALTER TABLE public.card OWNER TO postgres;

--
-- Name: card_label; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.card_label (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    label_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.card_label OWNER TO postgres;

--
-- Name: card_membership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.card_membership (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.card_membership OWNER TO postgres;

--
-- Name: card_subscription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.card_subscription (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    is_permanent boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.card_subscription OWNER TO postgres;

--
-- Name: comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comment (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint,
    text text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.comment OWNER TO postgres;

--
-- Name: config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config (
    id bigint DEFAULT public.next_id() NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    smtp_host text,
    smtp_port integer,
    smtp_name text,
    smtp_secure boolean NOT NULL,
    smtp_tls_reject_unauthorized boolean NOT NULL,
    smtp_user text,
    smtp_password text,
    smtp_from text
);


ALTER TABLE public.config OWNER TO postgres;

--
-- Name: custom_field; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_field (
    id bigint DEFAULT public.next_id() NOT NULL,
    base_custom_field_group_id bigint,
    custom_field_group_id bigint,
    "position" double precision NOT NULL,
    name text NOT NULL,
    show_on_front_of_card boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.custom_field OWNER TO postgres;

--
-- Name: custom_field_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_field_group (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint,
    card_id bigint,
    base_custom_field_group_id bigint,
    "position" double precision NOT NULL,
    name text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.custom_field_group OWNER TO postgres;

--
-- Name: custom_field_value; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_field_value (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    custom_field_group_id bigint NOT NULL,
    custom_field_id bigint NOT NULL,
    content text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.custom_field_value OWNER TO postgres;

--
-- Name: identity_provider_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.identity_provider_user (
    id bigint DEFAULT public.next_id() NOT NULL,
    user_id bigint NOT NULL,
    issuer text NOT NULL,
    sub text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.identity_provider_user OWNER TO postgres;

--
-- Name: internal_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.internal_config (
    id bigint DEFAULT public.next_id() NOT NULL,
    storage_limit text,
    active_users_limit integer,
    is_initialized boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.internal_config OWNER TO postgres;

--
-- Name: label; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.label (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text,
    color text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.label OWNER TO postgres;

--
-- Name: list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.list (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint NOT NULL,
    type text NOT NULL,
    "position" double precision,
    name text,
    color text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.list OWNER TO postgres;

--
-- Name: migration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migration (
    id integer NOT NULL,
    name character varying(255),
    batch integer,
    migration_time timestamp with time zone
);


ALTER TABLE public.migration OWNER TO postgres;

--
-- Name: migration_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migration_id_seq OWNER TO postgres;

--
-- Name: migration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migration_id_seq OWNED BY public.migration.id;


--
-- Name: migration_lock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migration_lock (
    index integer NOT NULL,
    is_locked integer
);


ALTER TABLE public.migration_lock OWNER TO postgres;

--
-- Name: migration_lock_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migration_lock_index_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migration_lock_index_seq OWNER TO postgres;

--
-- Name: migration_lock_index_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migration_lock_index_seq OWNED BY public.migration_lock.index;


--
-- Name: next_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.next_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.next_id_seq OWNER TO postgres;

--
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification (
    id bigint DEFAULT public.next_id() NOT NULL,
    user_id bigint NOT NULL,
    creator_user_id bigint,
    board_id bigint NOT NULL,
    card_id bigint NOT NULL,
    comment_id bigint,
    action_id bigint,
    type text NOT NULL,
    data jsonb NOT NULL,
    is_read boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.notification OWNER TO postgres;

--
-- Name: notification_service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_service (
    id bigint DEFAULT public.next_id() NOT NULL,
    user_id bigint,
    board_id bigint,
    url text NOT NULL,
    format text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.notification_service OWNER TO postgres;

--
-- Name: project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project (
    id bigint DEFAULT public.next_id() NOT NULL,
    owner_project_manager_id bigint,
    background_image_id bigint,
    name text NOT NULL,
    description text,
    background_type text,
    background_gradient text,
    is_hidden boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.project OWNER TO postgres;

--
-- Name: project_favorite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_favorite (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.project_favorite OWNER TO postgres;

--
-- Name: project_manager; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_manager (
    id bigint DEFAULT public.next_id() NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.project_manager OWNER TO postgres;

--
-- Name: session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.session (
    id bigint DEFAULT public.next_id() NOT NULL,
    user_id bigint NOT NULL,
    access_token text,
    http_only_token text,
    remote_address text NOT NULL,
    user_agent text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    pending_token text
);


ALTER TABLE public.session OWNER TO postgres;

--
-- Name: storage_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage_usage (
    id bigint DEFAULT public.next_id() NOT NULL,
    total bigint NOT NULL,
    user_avatars bigint NOT NULL,
    background_images bigint NOT NULL,
    attachments bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.storage_usage OWNER TO postgres;

--
-- Name: task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task (
    id bigint DEFAULT public.next_id() NOT NULL,
    task_list_id bigint NOT NULL,
    assignee_user_id bigint,
    "position" double precision NOT NULL,
    name text NOT NULL,
    is_completed boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    linked_card_id bigint
);


ALTER TABLE public.task OWNER TO postgres;

--
-- Name: task_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_list (
    id bigint DEFAULT public.next_id() NOT NULL,
    card_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    show_on_front_of_card boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hide_completed_tasks boolean NOT NULL
);


ALTER TABLE public.task_list OWNER TO postgres;

--
-- Name: uploaded_file; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.uploaded_file (
    id text DEFAULT public.next_id() NOT NULL,
    references_total integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type text NOT NULL,
    mime_type text,
    size bigint NOT NULL
);


ALTER TABLE public.uploaded_file OWNER TO postgres;

--
-- Name: user_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_account (
    id bigint DEFAULT public.next_id() NOT NULL,
    email text NOT NULL,
    password text,
    role text NOT NULL,
    name text NOT NULL,
    username text,
    avatar jsonb,
    phone text,
    organization text,
    language text,
    subscribe_to_own_cards boolean NOT NULL,
    subscribe_to_card_when_commenting boolean NOT NULL,
    turn_off_recent_card_highlighting boolean NOT NULL,
    enable_favorites_by_default boolean NOT NULL,
    default_editor_mode text NOT NULL,
    default_home_view text NOT NULL,
    default_projects_order text NOT NULL,
    is_sso_user boolean NOT NULL,
    is_deactivated boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    password_changed_at timestamp without time zone,
    terms_signature text,
    terms_accepted_at timestamp without time zone,
    api_key_prefix text,
    api_key_hash text,
    api_key_created_at timestamp without time zone
);


ALTER TABLE public.user_account OWNER TO postgres;

--
-- Name: webhook; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.webhook (
    id bigint DEFAULT public.next_id() NOT NULL,
    board_id bigint,
    name text NOT NULL,
    url text NOT NULL,
    access_token text,
    events text[],
    excluded_events text[],
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.webhook OWNER TO postgres;

--
-- Name: migration id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration ALTER COLUMN id SET DEFAULT nextval('public.migration_id_seq'::regclass);


--
-- Name: migration_lock index; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_lock ALTER COLUMN index SET DEFAULT nextval('public.migration_lock_index_seq'::regclass);


--
-- Data for Name: action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.action (id, card_id, user_id, type, data, created_at, updated_at, board_id) FROM stdin;
1757428782743946252	1757428782668448779	1757414626749842433	createCard	{"card": {"name": "dfhdfgh"}, "list": {"id": "1757421403520369673", "name": "BackLogs", "type": "active"}}	2026-04-20 13:57:16.626	\N	1757420994668004357
1757500534366930709	1757500534324987668	1757414626749842433	createCard	{"card": {"name": "Integrar autenticação central com marks1 API"}, "list": {"id": "1757500532991198989", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.086	\N	1757500532622100233
1757500535365175065	1757500535331620632	1757414626749842433	createCard	{"card": {"name": "Entregar dashboard do mapa"}, "list": {"id": "1757500532991198989", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.205	\N	1757500532622100233
1757500536204035869	1757500536170481436	1757414626749842433	createCard	{"card": {"name": "Entregar endpoints oficiais de importação/exportação"}, "list": {"id": "1757500532991198989", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.305	\N	1757500532622100233
1757500537042896673	1757500537009342240	1757414626749842433	createCard	{"card": {"name": "Implementar MVP do mapa"}, "list": {"id": "1757500532991198989", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.405	\N	1757500532622100233
1757500537856591653	1757500537831425828	1757414626749842433	createCard	{"card": {"name": "Integrar memórias via WG"}, "list": {"id": "1757500532991198989", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.503	\N	1757500532622100233
1757500540691941173	1757500540658386740	1757414626749842433	createCard	{"card": {"name": "Curar importação de comentários, checklists, dependências, anexos e tickets"}, "list": {"id": "1757500538779338541", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.84	\N	1757500538502514473
1757500541472081721	1757500541446915896	1757414626749842433	createCard	{"card": {"name": "Definir critérios de upsert e dedupe para importações incrementais"}, "list": {"id": "1757500538779338541", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:50.933	\N	1757500538502514473
1757500542126393148	1757500542092838715	1757414626749842433	createCard	{"card": {"name": "Estabelecer pipeline de reconciliação entre Work360 e map"}, "list": {"id": "1757500538779338541", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.011	\N	1757500538502514473
1757500542856202048	1757500542831036223	1757414626749842433	createCard	{"card": {"name": "Aplicar curadoria semântica para evitar ruído na Onda 4"}, "list": {"id": "1757500538779338541", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.099	\N	1757500538502514473
1757500543678285636	1757500543644731203	1757414626749842433	createCard	{"card": {"name": "Consolidar coleta estruturada de work items do Work360"}, "list": {"id": "1757500538779338541", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.196	\N	1757500538502514473
1757500545985152852	1757500545959987027	1757414626749842433	createCard	{"card": {"name": "Consolidar marks3 como nó de controle do failover"}, "list": {"id": "1757500544676529996", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.472	\N	1757500544366151496
1757500546857568088	1757500546824013655	1757414626749842433	createCard	{"card": {"name": "Consolidar engine de atualização DNS com reconciliação segura"}, "list": {"id": "1757500544676529996", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.576	\N	1757500544366151496
1757500547805480796	1757500547780314971	1757414626749842433	createCard	{"card": {"name": "Reconsolidar checagens de saúde para decisão de failover"}, "list": {"id": "1757500544676529996", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.689	\N	1757500544366151496
1757500548736616288	1757500548711450463	1757414626749842433	createCard	{"card": {"name": "Operacionalizar validações WireGuard-aware na priorização de alvos"}, "list": {"id": "1757500544676529996", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:51.799	\N	1757500544366151496
1757500551077037936	1757500551035094895	1757414626749842433	createCard	{"card": {"name": "Consolidar runtime do serviço público /chat"}, "list": {"id": "1757500549692917608", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.078	\N	1757500549374150500
1757500551865567092	1757500551832012659	1757414626749842433	createCard	{"card": {"name": "Reconsolidar políticas iniciais de roteamento de modelos"}, "list": {"id": "1757500549692917608", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.172	\N	1757500549374150500
1757500552578598776	1757500552545044343	1757414626749842433	createCard	{"card": {"name": "Operacionalizar serving multi-node e reconciliação de nós"}, "list": {"id": "1757500549692917608", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.258	\N	1757500549374150500
1757500554919020424	1757500554885465991	1757414626749842433	createCard	{"card": {"name": "Ações operacionais da malha/WG implementadas"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.537	\N	1757500553190967164
1757500555690772363	1757500555657217930	1757414626749842433	createCard	{"card": {"name": "Entregar ZeroTrust Screen — Fase 1"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.628	\N	1757500553190967164
1757500556428969870	1757500556395415437	1757414626749842433	createCard	{"card": {"name": "Entregar ZeroTrust Screen — Fase 2"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.717	\N	1757500553190967164
1757500557175555985	1757500557142001552	1757414626749842433	createCard	{"card": {"name": "Entregar ZeroTrust Screen — Fase 3"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.805	\N	1757500553190967164
1757500558006028181	1757500557980862356	1757414626749842433	createCard	{"card": {"name": "Ciclo de vida de peers operacionalizado"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:52.905	\N	1757500553190967164
1757500559297873817	1757500559264319384	1757414626749842433	createCard	{"card": {"name": "Monitoramento de saúde/handshake de túneis operacional"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.059	\N	1757500553190967164
1757500559985739676	1757500559952185243	1757414626749842433	createCard	{"card": {"name": "Reconciliação malha ativa vs inventário esperado operacional"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.14	\N	1757500553190967164
1757500560883320736	1757500560841377695	1757414626749842433	createCard	{"card": {"name": "Topologia WireGuard canônica consolidada"}, "list": {"id": "1757500553543288704", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.247	\N	1757500553190967164
1757500563307628464	1757500563257296815	1757414626749842433	createCard	{"card": {"name": "Consolidar fila canônica de comandos remotos"}, "list": {"id": "1757500561915119528", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.534	\N	1757500561621518244
1757500564037437363	1757500564012271538	1757414626749842433	createCard	{"card": {"name": "Operacionalizar reconciliação de comandos pendentes e expirados"}, "list": {"id": "1757500561915119528", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.624	\N	1757500561621518244
1757500564893075383	1757500564859520950	1757414626749842433	createCard	{"card": {"name": "Consolidar baseline de heartbeat dos nós guardian"}, "list": {"id": "1757500561915119528", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.725	\N	1757500561621518244
1757500565790656443	1757500565757102010	1757414626749842433	createCard	{"card": {"name": "Reconciliar telemetria operacional entre guardian e markspanel"}, "list": {"id": "1757500561915119528", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:53.832	\N	1757500561621518244
1757500567946528715	1757500567912974282	1757414626749842433	createCard	{"card": {"name": "Revisar runtime de automação com segurança operacional"}, "list": {"id": "1757500566654683075", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.09	\N	1757500566369470399
1757500568567285710	1757500568542119885	1757414626749842433	createCard	{"card": {"name": "Smoke task via integration API"}, "list": {"id": "1757500566654683075", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.164	\N	1757500566369470399
1757500569448089554	1757500569422923729	1757414626749842433	createCard	{"card": {"name": "Alinhar human memory, context recall e map integration"}, "list": {"id": "1757500566654683075", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.268	\N	1757500566369470399
1757500570152732630	1757500570127566805	1757414626749842433	createCard	{"card": {"name": "Consolidar integração com memórias persistentes"}, "list": {"id": "1757500566654683075", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.353	\N	1757500566369470399
1757500570882541530	1757500570848987097	1757414626749842433	createCard	{"card": {"name": "Reconciliar memória de sessão do MarksCode"}, "list": {"id": "1757500566654683075", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.439	\N	1757500566369470399
1757500576939115522	1757500576897172481	1757414626749842433	createCard	{"card": {"name": "Reconciliar autenticação central do painel"}, "list": {"id": "1757500575487887354", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.161	\N	1757500575244617718
1757500577794753542	1757500577769587717	1757414626749842433	createCard	{"card": {"name": "Consolidar visão operacional principal do painel"}, "list": {"id": "1757500575487887354", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.263	\N	1757500575244617718
1757500578491008010	1757500578457453577	1757414626749842433	createCard	{"card": {"name": "Alinhar workflows canônicos do operador"}, "list": {"id": "1757500575487887354", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.346	\N	1757500575244617718
1757500580890149914	1757500580864984089	1757414626749842433	createCard	{"card": {"name": "Revisar política canônica de backup inicial"}, "list": {"id": "1757500579371811858", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.632	\N	1757500579111765006
1757500581636736030	1757500581603181597	1757414626749842433	createCard	{"card": {"name": "Alinhar inventário e host roles canônicos"}, "list": {"id": "1757500579371811858", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.721	\N	1757500579111765006
1757500582576260130	1757500582542705697	1757414626749842433	createCard	{"card": {"name": "Consolidar baseline de monitoramento operacional"}, "list": {"id": "1757500579371811858", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.833	\N	1757500579111765006
1757500583348012070	1757500583314457637	1757414626749842433	createCard	{"card": {"name": "Reconsolidar serviços críticos do cluster"}, "list": {"id": "1757500579371811858", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:55.925	\N	1757500579111765006
1757500573197797354	1757500573172631529	1757414626749842433	createCard	{"card": {"name": "Alinhar recall humano e contexto operacional"}, "list": {"id": "1757500571805288418", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.716	\N	1757500571570407390
1757500573902440430	1757500573868885997	1757414626749842433	createCard	{"card": {"name": "Consolidar camadas de memória persistente"}, "list": {"id": "1757500571805288418", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.799	\N	1757500571570407390
1757500574682580978	1757500574657415153	1757414626749842433	createCard	{"card": {"name": "Reconciliar memória de sessão e continuidade"}, "list": {"id": "1757500571805288418", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:54.892	\N	1757500571570407390
1757500585570993206	1757500585545827381	1757414626749842433	createCard	{"card": {"name": "Reconsolidar catálogo inicial de apps e ofertas"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.191	\N	1757500584044266538
1757500586325967930	1757500586284024889	1757414626749842433	createCard	{"card": {"name": "Integrar map com memories marks1"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.28	\N	1757500584044266538
1757500587022222397	1757500586971890748	1757414626749842433	createCard	{"card": {"name": "Persistir evento no memories"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.363	\N	1757500584044266538
1757500588179850304	1757500588154684479	1757414626749842433	createCard	{"card": {"name": "Testar integracao memories"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.502	\N	1757500584044266538
1757500588842550339	1757500588808995906	1757414626749842433	createCard	{"card": {"name": "Validar MVP do map"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.58	\N	1757500584044266538
1757500589572359239	1757500589538804806	1757414626749842433	createCard	{"card": {"name": "Operacionalizar fluxo inicial de provisionamento e reconciliação"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.667	\N	1757500584044266538
1757500590277002315	1757500590243447882	1757414626749842433	createCard	{"card": {"name": "Consolidar modelo canônico de tenants do SaaS Hub"}, "list": {"id": "1757500584295924782", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:56.751	\N	1757500584044266538
1757500592726475867	1757500592692921434	1757414626749842433	createCard	{"card": {"name": "Task criada via receiver + map"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.043	\N	1757500590981645391
1757500593397564510	1757500593372398685	1757414626749842433	createCard	{"card": {"name": "Task criada via receiver real"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.123	\N	1757500590981645391
1757500594362254434	1757500594320311393	1757414626749842433	createCard	{"card": {"name": "Revisar integrações-base do ecossistema"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.239	\N	1757500590981645391
1757500595243058277	1757500595217892452	1757414626749842433	createCard	{"card": {"name": "Task criada com module real"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.343	\N	1757500590981645391
1757500595888981096	1757500595855426663	1757414626749842433	createCard	{"card": {"name": "Task criada via receiver com module real"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.421	\N	1757500590981645391
1757500596610401388	1757500596576846955	1757414626749842433	createCard	{"card": {"name": "Consolidar fronteiras entre sistemas centrais"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.506	\N	1757500590981645391
1757500597281490032	1757500597256324207	1757414626749842433	createCard	{"card": {"name": "Reconsolidar taxonomia canônica do ecossistema"}, "list": {"id": "1757500591283635283", "name": "BackLogs", "type": "active"}}	2026-04-20 16:19:57.586	\N	1757500590981645391
\.


--
-- Data for Name: attachment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attachment (id, card_id, creator_user_id, type, data, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: background_image; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.background_image (id, project_id, uploaded_file_id, extension, size, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: base_custom_field_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.base_custom_field_group (id, project_id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: board; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.board (id, project_id, "position", name, default_view, default_card_type, limit_card_types_to_default_one, always_display_card_creator, created_at, updated_at, expand_task_lists_by_default, display_card_ages) FROM stdin;
1757420994668004357	1757420872932525059	65536	BackLogs	kanban	project	f	f	2026-04-20 13:41:48.208	2026-04-20 13:42:14.687	f	f
1757500584044266538	1757500583750665256	65535	Execução	kanban	project	f	f	2026-04-20 16:19:56.009	\N	f	f
1757500590981645391	1757500590646101069	65535	Execução	kanban	project	f	f	2026-04-20 16:19:56.835	\N	f	f
1757490462484072191	1757490424282351357	65536	fwfgew	list	project	f	f	2026-04-20 15:59:49.424	2026-04-20 15:59:53.097	f	f
1757500532622100233	1757500532269778695	65535	Execução	kanban	project	f	f	2026-04-20 16:19:49.878	\N	f	f
1757500538502514473	1757500538183747367	65535	Execução	kanban	project	f	f	2026-04-20 16:19:50.578	\N	f	f
1757500544366151496	1757500544022218566	65535	Execução	kanban	project	f	f	2026-04-20 16:19:51.278	\N	f	f
1757500549374150500	1757500549072160610	65535	Execução	kanban	project	f	f	2026-04-20 16:19:51.876	\N	f	f
1757500553190967164	1757500552905754490	65535	Execução	kanban	project	f	f	2026-04-20 16:19:52.33	\N	f	f
1757500561621518244	1757500561252419490	65535	Execução	kanban	project	f	f	2026-04-20 16:19:53.335	\N	f	f
1757500566369470399	1757500566109423549	65535	Execução	kanban	project	f	f	2026-04-20 16:19:53.902	\N	f	f
1757500571570407390	1757500571276806108	65535	Execução	kanban	project	f	f	2026-04-20 16:19:54.522	\N	f	f
1757500575244617718	1757500574992959476	65535	Execução	kanban	project	f	f	2026-04-20 16:19:54.96	\N	f	f
1757500579111765006	1757500578851718156	65535	Execução	kanban	project	f	f	2026-04-20 16:19:55.42	\N	f	f
\.


--
-- Data for Name: board_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.board_membership (id, project_id, board_id, user_id, role, can_comment, created_at, updated_at) FROM stdin;
1757420994701558790	1757420872932525059	1757420994668004357	1757414626749842433	editor	\N	2026-04-20 13:41:48.219	\N
1757490462500849408	1757490424282351357	1757490462484072191	1757414626749842433	editor	\N	2026-04-20 15:59:49.426	\N
1757500532638877450	1757500532269778695	1757500532622100233	1757414626749842433	editor	\N	2026-04-20 16:19:49.881	\N
1757500538519291690	1757500538183747367	1757500538502514473	1757414626749842433	editor	\N	2026-04-20 16:19:50.581	\N
1757500544382928713	1757500544022218566	1757500544366151496	1757414626749842433	editor	\N	2026-04-20 16:19:51.28	\N
1757500549399316325	1757500549072160610	1757500549374150500	1757414626749842433	editor	\N	2026-04-20 16:19:51.877	\N
1757500553199355773	1757500552905754490	1757500553190967164	1757414626749842433	editor	\N	2026-04-20 16:19:52.332	\N
1757500561638295461	1757500561252419490	1757500561621518244	1757414626749842433	editor	\N	2026-04-20 16:19:53.336	\N
1757500566386247616	1757500566109423549	1757500566369470399	1757414626749842433	editor	\N	2026-04-20 16:19:53.903	\N
1757500571578795999	1757500571276806108	1757500571570407390	1757414626749842433	editor	\N	2026-04-20 16:19:54.523	\N
1757500575253006327	1757500574992959476	1757500575244617718	1757414626749842433	editor	\N	2026-04-20 16:19:54.961	\N
1757500579120153615	1757500578851718156	1757500579111765006	1757414626749842433	editor	\N	2026-04-20 16:19:55.421	\N
1757500584061043755	1757500583750665256	1757500584044266538	1757414626749842433	editor	\N	2026-04-20 16:19:56.01	\N
1757500590990034000	1757500590646101069	1757500590981645391	1757414626749842433	editor	\N	2026-04-20 16:19:56.837	\N
\.


--
-- Data for Name: board_subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.board_subscription (id, board_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: card; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, type, "position", name, description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed) FROM stdin;
1757428782668448779	1757420994668004357	1757421403520369673	1757414626749842433	\N	\N	project	65536	dfhdfgh	\N	\N	\N	2026-04-20 13:57:16.612	\N	2026-04-20 13:57:16.61	0	f	\N
1757500534324987668	1757500532622100233	1757500532991198989	1757414626749842433	\N	\N	story	65535	Integrar autenticação central com marks1 API	Autenticação central do map integrada com /auth e /auth/me do marks1.\n\n---\nMapStableKey: fallback:map-project:central-auth:integrar-autenticação-central-com-marks1-api\nMapTaskId: \nproject_slug: map-project\nmodule_slug: central-auth\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:50.081	\N	2026-04-20 16:19:50.08	0	f	\N
1757500535331620632	1757500532622100233	1757500532991198989	1757414626749842433	\N	\N	story	81919	Entregar dashboard do mapa	Dashboard web do map entregue com páginas, formulários e visão operacional.\n\n---\nMapStableKey: fallback:map-project:dashboard:entregar-dashboard-do-mapa\nMapTaskId: \nproject_slug: map-project\nmodule_slug: dashboard\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:50.201	\N	2026-04-20 16:19:50.2	0	f	\N
1757500536170481436	1757500532622100233	1757500532991198989	1757414626749842433	\N	\N	story	73727	Entregar endpoints oficiais de importação/exportação	Import/export oficial do map entregue e validado na instância principal.\n\n---\nMapStableKey: fallback:map-project:import-export:entregar-endpoints-oficiais-de-importação-exportação\nMapTaskId: \nproject_slug: map-project\nmodule_slug: import-export\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:50.301	\N	2026-04-20 16:19:50.301	0	f	\N
1757500537009342240	1757500532622100233	1757500532991198989	1757414626749842433	\N	\N	story	69631	Implementar MVP do mapa	MVP do módulo map implementado, validado localmente e operacionalizado.\n\n---\nMapStableKey: fallback:map-project:map-mvp:implementar-mvp-do-mapa\nMapTaskId: \nproject_slug: map-project\nmodule_slug: map-mvp\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:50.401	\N	2026-04-20 16:19:50.401	0	f	\N
1757500537831425828	1757500532622100233	1757500532991198989	1757414626749842433	\N	\N	story	67583	Integrar memórias via WG	Integração do map com memories no marks1 via WireGuard concluída e validada.\n\n---\nMapStableKey: fallback:map-project:memories-integration:integrar-memórias-via-wg\nMapTaskId: \nproject_slug: map-project\nmodule_slug: memories-integration\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:50.499	\N	2026-04-20 16:19:50.499	0	f	\N
1757500540658386740	1757500538502514473	1757500538779338541	1757414626749842433	\N	\N	story	65535	Curar importação de comentários, checklists, dependências, anexos e tickets	Definir uma leitura estruturada dos sinais auxiliares do Work360, priorizando contexto útil e evitando importar conteúdo bruto demais como tarefa operacional.\n\n---\nMapStableKey: fallback:work360-integration:auxiliary-signals-harvesting:curar-importação-de-comentários-checklists-dependências-anexos-e-tickets\nMapTaskId: \nproject_slug: work360-integration\nmodule_slug: auxiliary-signals-harvesting\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:50.836	\N	2026-04-20 16:19:50.835	0	f	\N
1757500541446915896	1757500538502514473	1757500538779338541	1757414626749842433	\N	\N	story	81919	Definir critérios de upsert e dedupe para importações incrementais	Garantir que reimportações do Work360 atualizem contexto existente quando apropriado, sem duplicar módulos ou criar tarefas redundantes no map.\n\n---\nMapStableKey: fallback:work360-integration:map-reconciliation-pipeline:definir-critérios-de-upsert-e-dedupe-para-importações-incrementais\nMapTaskId: \nproject_slug: work360-integration\nmodule_slug: map-reconciliation-pipeline\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:50.93	\N	2026-04-20 16:19:50.929	0	f	\N
1757500542092838715	1757500538502514473	1757500538779338541	1757414626749842433	\N	\N	story	73727	Estabelecer pipeline de reconciliação entre Work360 e map	Consolidar regras para associar work items coletados a projetos, módulos e tasks do map com deduplicação e vínculo semântico claro.\n\n---\nMapStableKey: fallback:work360-integration:map-reconciliation-pipeline:estabelecer-pipeline-de-reconciliação-entre-work360-e-map\nMapTaskId: \nproject_slug: work360-integration\nmodule_slug: map-reconciliation-pipeline\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:51.008	\N	2026-04-20 16:19:51.007	0	f	\N
1757500542831036223	1757500538502514473	1757500538779338541	1757414626749842433	\N	\N	story	69631	Aplicar curadoria semântica para evitar ruído na Onda 4	Restringir a importação canônica desta onda a itens claramente acionáveis, com foco em consolidação, reconciliação e governança do pipeline de integração.\n\n---\nMapStableKey: fallback:work360-integration:safe-import-governance:aplicar-curadoria-semântica-para-evitar-ruído-na-onda-4\nMapTaskId: \nproject_slug: work360-integration\nmodule_slug: safe-import-governance\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:51.095	\N	2026-04-20 16:19:51.094	0	f	\N
1757500543644731203	1757500538502514473	1757500538779338541	1757414626749842433	\N	\N	story	67583	Consolidar coleta estruturada de work items do Work360	Padronizar a captura de detalhamento inicial dos work items para gerar base canônica consistente antes de qualquer reconciliação no map.\n\n---\nMapStableKey: fallback:work360-integration:structured-workitem-collection:consolidar-coleta-estruturada-de-work-items-do-work360\nMapTaskId: \nproject_slug: work360-integration\nmodule_slug: structured-workitem-collection\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:51.193	\N	2026-04-20 16:19:51.192	0	f	\N
1757500545959987027	1757500544366151496	1757500544676529996	1757414626749842433	\N	\N	story	65535	Consolidar marks3 como nó de controle do failover	Representar no map o papel do marks3 como control-plane operacional e ponto de reconciliação do sistema.\n\n---\nMapStableKey: fallback:cloudflare-dns-failover:control-plane-node:consolidar-marks3-como-nó-de-controle-do-failover\nMapTaskId: \nproject_slug: cloudflare-dns-failover\nmodule_slug: control-plane-node\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:51.469	\N	2026-04-20 16:19:51.468	0	f	\N
1757500546824013655	1757500544366151496	1757500544676529996	1757414626749842433	\N	\N	story	81919	Consolidar engine de atualização DNS com reconciliação segura	Mapear o fluxo mínimo de atualização, verificação e reconciliação de registros no Cloudflare.\n\n---\nMapStableKey: fallback:cloudflare-dns-failover:dns-update-engine:consolidar-engine-de-atualização-dns-com-reconciliação-segura\nMapTaskId: \nproject_slug: cloudflare-dns-failover\nmodule_slug: dns-update-engine\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:51.572	\N	2026-04-20 16:19:51.57	0	f	\N
1757500547780314971	1757500544366151496	1757500544676529996	1757414626749842433	\N	\N	story	73727	Reconsolidar checagens de saúde para decisão de failover	Organizar o conjunto mínimo de sinais e verificações usados para detectar degradação real dos alvos.\n\n---\nMapStableKey: fallback:cloudflare-dns-failover:health-checks:reconsolidar-checagens-de-saúde-para-decisão-de-failover\nMapTaskId: \nproject_slug: cloudflare-dns-failover\nmodule_slug: health-checks\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:51.685	\N	2026-04-20 16:19:51.684	0	f	\N
1757500548711450463	1757500544366151496	1757500544676529996	1757414626749842433	\N	\N	story	69631	Operacionalizar validações WireGuard-aware na priorização de alvos	Definir checagens iniciais que respeitem prioridade de rotas e disponibilidade observada via WireGuard.\n\n---\nMapStableKey: fallback:cloudflare-dns-failover:wg-priority-checks:operacionalizar-validações-wireguard-aware-na-priorização-de-alvos\nMapTaskId: \nproject_slug: cloudflare-dns-failover\nmodule_slug: wg-priority-checks\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:51.796	\N	2026-04-20 16:19:51.795	0	f	\N
1757500551035094895	1757500549374150500	1757500549692917608	1757414626749842433	\N	\N	story	65535	Consolidar runtime do serviço público /chat	Revisar o fluxo mínimo do endpoint público para garantir representação canônica do serviço no map.\n\n---\nMapStableKey: fallback:chat-marks:chat-runtime:consolidar-runtime-do-serviço-público-chat\nMapTaskId: \nproject_slug: chat-marks\nmodule_slug: chat-runtime\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:52.073	\N	2026-04-20 16:19:52.072	0	f	\N
1757500551832012659	1757500549374150500	1757500549692917608	1757414626749842433	\N	\N	story	81919	Reconsolidar políticas iniciais de roteamento de modelos	Organizar critérios operacionais mínimos para seleção e fallback de modelos no chat.\n\n---\nMapStableKey: fallback:chat-marks:model-routing:reconsolidar-políticas-iniciais-de-roteamento-de-modelos\nMapTaskId: \nproject_slug: chat-marks\nmodule_slug: model-routing\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:52.168	\N	2026-04-20 16:19:52.168	0	f	\N
1757500552545044343	1757500549374150500	1757500549692917608	1757414626749842433	\N	\N	story	73727	Operacionalizar serving multi-node e reconciliação de nós	Mapear os nós de serving, checagens básicas e reconciliação do estado operacional do chat.\n\n---\nMapStableKey: fallback:chat-marks:serving-nodes:operacionalizar-serving-multi-node-e-reconciliação-de-nós\nMapTaskId: \nproject_slug: chat-marks\nmodule_slug: serving-nodes\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:52.253	\N	2026-04-20 16:19:52.253	0	f	\N
1757500563257296815	1757500561621518244	1757500561915119528	1757414626749842433	\N	\N	story	65535	Consolidar fila canônica de comandos remotos	Padronizar o fluxo mínimo de pull, ack e resultado para execução auditável e idempotente no fleet.\n\n---\nMapStableKey: fallback:guardian-control-plane:command-queue:consolidar-fila-canônica-de-comandos-remotos\nMapTaskId: \nproject_slug: guardian-control-plane\nmodule_slug: command-queue\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:53.53	\N	2026-04-20 16:19:53.529	0	f	\N
1757500564012271538	1757500561621518244	1757500561915119528	1757414626749842433	\N	\N	story	81919	Operacionalizar reconciliação de comandos pendentes e expirados	Definir rotina inicial para limpar divergências entre comandos emitidos, acknowledgements e resultados finais.\n\n---\nMapStableKey: fallback:guardian-control-plane:command-queue:operacionalizar-reconciliação-de-comandos-pendentes-e-expirados\nMapTaskId: \nproject_slug: guardian-control-plane\nmodule_slug: command-queue\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:53.62	\N	2026-04-20 16:19:53.619	0	f	\N
1757500564859520950	1757500561621518244	1757500561915119528	1757414626749842433	\N	\N	story	73727	Consolidar baseline de heartbeat dos nós guardian	Reconciliar presença, intervalo esperado e campos mínimos para refletir o estado real do fleet sem duplicar o painel.\n\n---\nMapStableKey: fallback:guardian-control-plane:heartbeat:consolidar-baseline-de-heartbeat-dos-nós-guardian\nMapTaskId: \nproject_slug: guardian-control-plane\nmodule_slug: heartbeat\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:53.721	\N	2026-04-20 16:19:53.72	0	f	\N
1757500565757102010	1757500561621518244	1757500561915119528	1757414626749842433	\N	\N	story	69631	Reconciliar telemetria operacional entre guardian e markspanel	Alinhar métricas, fontes e granularidade mínima para observabilidade consistente dos nós e serviços.\n\n---\nMapStableKey: fallback:guardian-control-plane:telemetry:reconciliar-telemetria-operacional-entre-guardian-e-markspanel\nMapTaskId: \nproject_slug: guardian-control-plane\nmodule_slug: telemetry\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:53.828	\N	2026-04-20 16:19:53.827	0	f	\N
1757500573172631529	1757500571570407390	1757500571805288418	1757414626749842433	\N	\N	story	65535	Alinhar recall humano e contexto operacional	Padronizar como contexto humano relevante será refletido e recuperado no sistema.\n\n---\nMapStableKey: fallback:memories:human-memory:alinhar-recall-humano-e-contexto-operacional\nMapTaskId: \nproject_slug: memories\nmodule_slug: human-memory\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:54.712	\N	2026-04-20 16:19:54.711	0	f	\N
1757500573868885997	1757500571570407390	1757500571805288418	1757414626749842433	\N	\N	story	81919	Consolidar camadas de memória persistente	Revisar a base persistente mínima para suportar recall e contexto contínuo.\n\n---\nMapStableKey: fallback:memories:persistent-memories:consolidar-camadas-de-memória-persistente\nMapTaskId: \nproject_slug: memories\nmodule_slug: persistent-memories\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:54.795	\N	2026-04-20 16:19:54.795	0	f	\N
1757500574657415153	1757500571570407390	1757500571805288418	1757414626749842433	\N	\N	story	73727	Reconciliar memória de sessão e continuidade	Alinhar limites e responsabilidades da memória de sessão no lote inicial.\n\n---\nMapStableKey: fallback:memories:session-memory:reconciliar-memória-de-sessão-e-continuidade\nMapTaskId: \nproject_slug: memories\nmodule_slug: session-memory\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:54.889	\N	2026-04-20 16:19:54.888	0	f	\N
1757500585545827381	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	65535	Reconsolidar catálogo inicial de apps e ofertas	Mapear os serviços centrais do hub em um catálogo mínimo, claro e reconciliável por tenant.\n\n---\nMapStableKey: fallback:saas-hub:app-catalog:reconsolidar-catálogo-inicial-de-apps-e-ofertas\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: app-catalog\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:56.188	\N	2026-04-20 16:19:56.187	0	f	\N
1757500586284024889	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	81919	Integrar map com memories marks1	Registrar task e validar contexto via WG.\n\n---\nMapStableKey: fallback:saas-hub:chat-ops:integrar-map-com-memories-marks1\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: chat-ops\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:56.275	\N	2026-04-20 16:19:56.275	0	f	\N
1757500586971890748	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	73727	Persistir evento no memories	Verificar escrita real do map no memories do marks1.\n\n---\nMapStableKey: fallback:saas-hub:chat-ops:persistir-evento-no-memories\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: chat-ops\nstatus: done\npriority: medium	\N	\N	2026-04-20 16:19:56.356	\N	2026-04-20 16:19:56.356	0	f	\N
1757500588154684479	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	69631	Testar integracao memories	Validar fallback seguro sem memories configurado.\n\n---\nMapStableKey: fallback:saas-hub:chat-ops:testar-integracao-memories\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: chat-ops\nstatus: done\npriority: medium	\N	\N	2026-04-20 16:19:56.498	\N	2026-04-20 16:19:56.497	0	f	\N
1757500588808995906	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	67583	Validar MVP do map	Subir o modulo e executar smoke tests.\n\n---\nMapStableKey: fallback:saas-hub:chat-ops:validar-mvp-do-map\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: chat-ops\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:56.576	\N	2026-04-20 16:19:56.576	0	f	\N
1757500589538804806	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	66559	Operacionalizar fluxo inicial de provisionamento e reconciliação	Definir o lote mínimo para ativação, verificação e reconciliação operacional de recursos do hub.\n\n---\nMapStableKey: fallback:saas-hub:provisioning:operacionalizar-fluxo-inicial-de-provisionamento-e-reconciliação\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: provisioning\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:56.664	\N	2026-04-20 16:19:56.663	0	f	\N
1757500590243447882	1757500584044266538	1757500584295924782	1757414626749842433	\N	\N	story	66047	Consolidar modelo canônico de tenants do SaaS Hub	Revisar entidades, estados e fronteiras operacionais para refletir tenants de forma consistente no map.\n\n---\nMapStableKey: fallback:saas-hub:tenant-management:consolidar-modelo-canônico-de-tenants-do-saas-hub\nMapTaskId: \nproject_slug: saas-hub\nmodule_slug: tenant-management\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:56.748	\N	2026-04-20 16:19:56.747	0	f	\N
1757500592692921434	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	65535	Task criada via receiver + map	Smoke test real fim a fim da bridge Planka -> Map\n\n---\nMapStableKey: fallback:ecosystem-marks:geral:task-criada-via-receiver-map\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: geral\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.039	\N	2026-04-20 16:19:57.038	0	f	\N
1757500593372398685	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	81919	Task criada via receiver real	Smoke test real da bridge Planka -> Map\n\n---\nMapStableKey: fallback:ecosystem-marks:geral:task-criada-via-receiver-real\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: geral\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.12	\N	2026-04-20 16:19:57.12	0	f	\N
1757500594320311393	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	73727	Revisar integrações-base do ecossistema	Mapear integrações prioritárias entre módulos canônicos já ativos no ambiente local.\n\n---\nMapStableKey: fallback:ecosystem-marks:integration:revisar-integrações-base-do-ecossistema\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: integration\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:57.233	\N	2026-04-20 16:19:57.232	0	f	\N
1757500595217892452	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	69631	Task criada com module real	Smoke test real da bridge Planka -> Map com labels resolvendo module\n\n---\nMapStableKey: fallback:ecosystem-marks:integration:task-criada-com-module-real\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: integration\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.34	\N	2026-04-20 16:19:57.339	0	f	\N
1757500554885465991	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	65535	Ações operacionais da malha/WG implementadas	Restart WG, revoke peer, connectivity test e firewall baseline validate/apply guiado implementados.\n\n---\nMapStableKey: fallback:zero-trust-network:markspanel:ações-operacionais-da-malha-wg-implementadas\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: markspanel\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:52.533	\N	2026-04-20 16:19:52.532	0	f	\N
1757500555657217930	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	81919	Entregar ZeroTrust Screen — Fase 1	Fase 1 read-only da tela ZeroTrust entregue no Markspanel.\n\n---\nMapStableKey: fallback:zero-trust-network:markspanel:entregar-zerotrust-screen-fase-1\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: markspanel\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:52.624	\N	2026-04-20 16:19:52.623	0	f	\N
1757500556395415437	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	73727	Entregar ZeroTrust Screen — Fase 2	Fase 2 com ações seguras e jobs operacionais entregue.\n\n---\nMapStableKey: fallback:zero-trust-network:markspanel:entregar-zerotrust-screen-fase-2\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: markspanel\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:52.713	\N	2026-04-20 16:19:52.711	0	f	\N
1757500557142001552	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	69631	Entregar ZeroTrust Screen — Fase 3	Fase 3 guided safe mode com plans/diff/confirm entregue.\n\n---\nMapStableKey: fallback:zero-trust-network:markspanel:entregar-zerotrust-screen-fase-3\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: markspanel\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:52.801	\N	2026-04-20 16:19:52.8	0	f	\N
1757500557980862356	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	67583	Ciclo de vida de peers operacionalizado	Padronizar onboarding, rotação e revogação com foco em operação segura e previsível da malha.\n\n---\nMapStableKey: fallback:zero-trust-network:peer-lifecycle:ciclo-de-vida-de-peers-operacionalizado\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: peer-lifecycle\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:52.901	\N	2026-04-20 16:19:52.9	0	f	\N
1757500559264319384	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	66559	Monitoramento de saúde/handshake de túneis operacional	Definir checks mínimos para detectar degradação de conectividade, handshakes ausentes e falhas de rota.\n\n---\nMapStableKey: fallback:zero-trust-network:tunnel-health:monitoramento-de-saúde-handshake-de-túneis-operacional\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: tunnel-health\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:53.055	\N	2026-04-20 16:19:53.054	0	f	\N
1757500559952185243	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	66047	Reconciliação malha ativa vs inventário esperado operacional	Comparar peers e túneis efetivos com o inventário canônico para reduzir drift operacional.\n\n---\nMapStableKey: fallback:zero-trust-network:tunnel-health:reconciliação-malha-ativa-vs-inventário-esperado-operacional\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: tunnel-health\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:53.136	\N	2026-04-20 16:19:53.136	0	f	\N
1757500560841377695	1757500553190967164	1757500553543288704	1757414626749842433	\N	\N	story	65791	Topologia WireGuard canônica consolidada	Reconciliar parâmetros-base, papéis dos nós e elementos compartilhados da malha sem acoplar detalhes excessivamente específicos.\n\n---\nMapStableKey: fallback:zero-trust-network:wg-concentrator:topologia-wireguard-canônica-consolidada\nMapTaskId: \nproject_slug: zero-trust-network\nmodule_slug: wg-concentrator\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:53.242	\N	2026-04-20 16:19:53.241	0	f	\N
1757500567912974282	1757500566369470399	1757500566654683075	1757414626749842433	\N	\N	story	65535	Revisar runtime de automação com segurança operacional	Conferir fronteiras, garantias e pontos críticos do runtime usado pelo MarksCode.\n\n---\nMapStableKey: fallback:markscode:automation-runtime:revisar-runtime-de-automação-com-segurança-operacional\nMapTaskId: \nproject_slug: markscode\nmodule_slug: automation-runtime\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:54.086	\N	2026-04-20 16:19:54.085	0	f	\N
1757500568542119885	1757500566369470399	1757500566654683075	1757414626749842433	\N	\N	story	81919	Smoke task via integration API	Validar contrato MarksCode ↔ Map em runtime real.\n\n---\nMapStableKey: fallback:markscode:automation-runtime:smoke-task-via-integration-api\nMapTaskId: \nproject_slug: markscode\nmodule_slug: automation-runtime\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:54.16	\N	2026-04-20 16:19:54.159	0	f	\N
1757500569422923729	1757500566369470399	1757500566654683075	1757414626749842433	\N	\N	story	73727	Alinhar human memory, context recall e map integration	Consolidar o vínculo canônico entre memória humana, recall de contexto e representação no map.\n\n---\nMapStableKey: fallback:markscode:human-memory-map-integration:alinhar-human-memory-context-recall-e-map-integration\nMapTaskId: \nproject_slug: markscode\nmodule_slug: human-memory-map-integration\nstatus: done\npriority: high	\N	\N	2026-04-20 16:19:54.265	\N	2026-04-20 16:19:54.264	0	f	\N
1757500570127566805	1757500566369470399	1757500566654683075	1757414626749842433	\N	\N	story	69631	Consolidar integração com memórias persistentes	Revisar como memórias persistentes são registradas e recuperadas pelo MarksCode.\n\n---\nMapStableKey: fallback:markscode:persistent-memories:consolidar-integração-com-memórias-persistentes\nMapTaskId: \nproject_slug: markscode\nmodule_slug: persistent-memories\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:54.349	\N	2026-04-20 16:19:54.348	0	f	\N
1757500570848987097	1757500566369470399	1757500566654683075	1757414626749842433	\N	\N	story	67583	Reconciliar memória de sessão do MarksCode	Padronizar responsabilidades da camada de sessão para manter continuidade de trabalho.\n\n---\nMapStableKey: fallback:markscode:session-memory:reconciliar-memória-de-sessão-do-markscode\nMapTaskId: \nproject_slug: markscode\nmodule_slug: session-memory\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:54.436	\N	2026-04-20 16:19:54.435	0	f	\N
1757500576897172481	1757500575244617718	1757500575487887354	1757414626749842433	\N	\N	story	65535	Reconciliar autenticação central do painel	Validar dependências e fronteiras da autenticação usada pelo ecossistema.\n\n---\nMapStableKey: fallback:markspanel:auth:reconciliar-autenticação-central-do-painel\nMapTaskId: \nproject_slug: markspanel\nmodule_slug: auth\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:55.156	\N	2026-04-20 16:19:55.155	0	f	\N
1757500577769587717	1757500575244617718	1757500575487887354	1757414626749842433	\N	\N	story	81919	Consolidar visão operacional principal do painel	Alinhar os blocos mais importantes da dashboard para operação diária.\n\n---\nMapStableKey: fallback:markspanel:dashboard:consolidar-visão-operacional-principal-do-painel\nMapTaskId: \nproject_slug: markspanel\nmodule_slug: dashboard\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:55.26	\N	2026-04-20 16:19:55.259	0	f	\N
1757500578457453577	1757500575244617718	1757500575487887354	1757414626749842433	\N	\N	story	73727	Alinhar workflows canônicos do operador	Mapear os fluxos operacionais prioritários e reduzir caminhos redundantes.\n\n---\nMapStableKey: fallback:markspanel:operator-workflows:alinhar-workflows-canônicos-do-operador\nMapTaskId: \nproject_slug: markspanel\nmodule_slug: operator-workflows\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:55.342	\N	2026-04-20 16:19:55.341	0	f	\N
1757500580864984089	1757500579111765006	1757500579371811858	1757414626749842433	\N	\N	story	65535	Revisar política canônica de backup inicial	Validar cobertura mínima, frequência e pontos de restauração prioritários.\n\n---\nMapStableKey: fallback:cluster-operations:backup:revisar-política-canônica-de-backup-inicial\nMapTaskId: \nproject_slug: cluster-operations\nmodule_slug: backup\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:55.629	\N	2026-04-20 16:19:55.628	0	f	\N
1757500581603181597	1757500579111765006	1757500579371811858	1757414626749842433	\N	\N	story	81919	Alinhar inventário e host roles canônicos	Padronizar hosts e papéis essenciais para navegação operacional dentro do map.\n\n---\nMapStableKey: fallback:cluster-operations:inventory:alinhar-inventário-e-host-roles-canônicos\nMapTaskId: \nproject_slug: cluster-operations\nmodule_slug: inventory\nstatus: open\npriority: normal	\N	\N	2026-04-20 16:19:55.717	\N	2026-04-20 16:19:55.716	0	f	\N
1757500582542705697	1757500579111765006	1757500579371811858	1757414626749842433	\N	\N	story	73727	Consolidar baseline de monitoramento operacional	Definir observabilidade mínima e checks principais para o lote inicial do cluster.\n\n---\nMapStableKey: fallback:cluster-operations:monitor:consolidar-baseline-de-monitoramento-operacional\nMapTaskId: \nproject_slug: cluster-operations\nmodule_slug: monitor\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:55.829	\N	2026-04-20 16:19:55.828	0	f	\N
1757500583314457637	1757500579111765006	1757500579371811858	1757414626749842433	\N	\N	story	69631	Reconsolidar serviços críticos do cluster	Listar e alinhar os serviços mais canônicos e seu papel operacional no ambiente.\n\n---\nMapStableKey: fallback:cluster-operations:services:reconsolidar-serviços-críticos-do-cluster\nMapTaskId: \nproject_slug: cluster-operations\nmodule_slug: services\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:55.922	\N	2026-04-20 16:19:55.921	0	f	\N
1757500595855426663	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	67583	Task criada via receiver com module real	Smoke test real fim a fim com labels -> module\n\n---\nMapStableKey: fallback:ecosystem-marks:integration:task-criada-via-receiver-com-module-real\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: integration\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.417	\N	2026-04-20 16:19:57.416	0	f	\N
1757500596576846955	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	66559	Consolidar fronteiras entre sistemas centrais	Revisar responsabilidades entre sistemas para reduzir sobreposição e ambiguidade.\n\n---\nMapStableKey: fallback:ecosystem-marks:orchestration:consolidar-fronteiras-entre-sistemas-centrais\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: orchestration\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.502	\N	2026-04-20 16:19:57.502	0	f	\N
1757500597256324207	1757500590981645391	1757500591283635283	1757414626749842433	\N	\N	story	66047	Reconsolidar taxonomia canônica do ecossistema	Validar e alinhar nomes, slugs e fronteiras entre projetos e módulos centrais.\n\n---\nMapStableKey: fallback:ecosystem-marks:taxonomy:reconsolidar-taxonomia-canônica-do-ecossistema\nMapTaskId: \nproject_slug: ecosystem-marks\nmodule_slug: taxonomy\nstatus: open\npriority: high	\N	\N	2026-04-20 16:19:57.583	\N	2026-04-20 16:19:57.582	0	f	\N
\.


--
-- Data for Name: card_label; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.card_label (id, card_id, label_id, created_at, updated_at) FROM stdin;
1757500534517925654	1757500534324987668	1757500533989443347	2026-04-20 16:19:50.105	\N
1757500535474226970	1757500535331620632	1757500534937356055	2026-04-20 16:19:50.219	\N
1757500536321476382	1757500536170481436	1757500535818159899	2026-04-20 16:19:50.32	\N
1757500537177114402	1757500537009342240	1757500536606689055	2026-04-20 16:19:50.421	\N
1757500537974032166	1757500537831425828	1757500537479104291	2026-04-20 16:19:50.517	\N
1757500540809381686	1757500540658386740	1757500540373174067	2026-04-20 16:19:50.854	\N
1757500541597910842	1757500541446915896	1757500541161703223	2026-04-20 16:19:50.948	\N
1757500542218667837	1757500542092838715	1757500541161703223	2026-04-20 16:19:51.023	\N
1757500542973642561	1757500542831036223	1757500542503880510	2026-04-20 16:19:51.112	\N
1757500543778948933	1757500543644731203	1757500543275632450	2026-04-20 16:19:51.209	\N
1757500546110981973	1757500545959987027	1757500545716717394	2026-04-20 16:19:51.487	\N
1757500547025340249	1757500546824013655	1757500546429749078	2026-04-20 16:19:51.595	\N
1757500548031973213	1757500547780314971	1757500547461547866	2026-04-20 16:19:51.715	\N
1757500548837279585	1757500548711450463	1757500548409460574	2026-04-20 16:19:51.812	\N
1757500551202867057	1757500551035094895	1757500550733105006	2026-04-20 16:19:52.093	\N
1757500551974618997	1757500551832012659	1757500551496468338	2026-04-20 16:19:52.185	\N
1757500552696039289	1757500552545044343	1757500552243054454	2026-04-20 16:19:52.271	\N
1757500555095181193	1757500554885465991	1757500554583476102	2026-04-20 16:19:52.557	\N
1757500555816601484	1757500555657217930	1757500554583476102	2026-04-20 16:19:52.643	\N
1757500556571576207	1757500556395415437	1757500554583476102	2026-04-20 16:19:52.733	\N
1757500557343328146	1757500557142001552	1757500554583476102	2026-04-20 16:19:52.825	\N
1757500558115080086	1757500557980862356	1757500557670483859	2026-04-20 16:19:52.918	\N
1757500559423702938	1757500559264319384	1757500558937163671	2026-04-20 16:19:53.073	\N
1757500560094791581	1757500559952185243	1757500558937163671	2026-04-20 16:19:53.153	\N
1757500560992372641	1757500560841377695	1757500560405170078	2026-04-20 16:19:53.261	\N
1757500563450234801	1757500563257296815	1757500562988861358	2026-04-20 16:19:53.553	\N
1757500564163266484	1757500564012271538	1757500562988861358	2026-04-20 16:19:53.638	\N
1757500565035681720	1757500564859520950	1757500564448479157	2026-04-20 16:19:53.743	\N
1757500565908096956	1757500565757102010	1757500565438334905	2026-04-20 16:19:53.847	\N
1757500568063969228	1757500567912974282	1757500567610984393	2026-04-20 16:19:54.103	\N
1757500568701503439	1757500568542119885	1757500567610984393	2026-04-20 16:19:54.179	\N
1757500569565530067	1757500569422923729	1757500569037047760	2026-04-20 16:19:54.283	\N
1757500570270173143	1757500570127566805	1757500569842354132	2026-04-20 16:19:54.366	\N
1757500571008370651	1757500570848987097	1757500570555385816	2026-04-20 16:19:54.455	\N
1757500573315237867	1757500573172631529	1757500572870641640	2026-04-20 16:19:54.73	\N
1757500574011492335	1757500573868885997	1757500573592061932	2026-04-20 16:19:54.812	\N
1757500574783244275	1757500574657415153	1757500574296705008	2026-04-20 16:19:54.905	\N
1757500577115276291	1757500576897172481	1757500576578405376	2026-04-20 16:19:55.182	\N
1757500577920582663	1757500577769587717	1757500577450820612	2026-04-20 16:19:55.279	\N
1757500578616837131	1757500578457453577	1757500578189018120	2026-04-20 16:19:55.361	\N
1757500581007590427	1757500580864984089	1757500580579771416	2026-04-20 16:19:55.646	\N
1757500581745787935	1757500581603181597	1757500581292803100	2026-04-20 16:19:55.734	\N
1757500582702089251	1757500582542705697	1757500582106498080	2026-04-20 16:19:55.849	\N
1757500583465452583	1757500583314457637	1757500582978913316	2026-04-20 16:19:55.939	\N
1757500585680045111	1757500585545827381	1757500585252226100	2026-04-20 16:19:56.204	\N
1757500586443408443	1757500586284024889	1757500585990423608	2026-04-20 16:19:56.294	\N
1757500587215160382	1757500586971890748	1757500585990423608	2026-04-20 16:19:56.386	\N
1757500588305679425	1757500588154684479	1757500585990423608	2026-04-20 16:19:56.516	\N
1757500588951602244	1757500588808995906	1757500585990423608	2026-04-20 16:19:56.594	\N
1757500589681411144	1757500589538804806	1757500589194871877	2026-04-20 16:19:56.68	\N
1757500590402831436	1757500590243447882	1757500589941457993	2026-04-20 16:19:56.766	\N
1757500592869082204	1757500592692921434	1757500592390931545	2026-04-20 16:19:57.061	\N
1757500593523393631	1757500593372398685	1757500592390931545	2026-04-20 16:19:57.139	\N
1757500594521637987	1757500594320311393	1757500593858937952	2026-04-20 16:19:57.257	\N
1757500595360498790	1757500595217892452	1757500593858937952	2026-04-20 16:19:57.358	\N
1757500595989644393	1757500595855426663	1757500593858937952	2026-04-20 16:19:57.433	\N
1757500596711064685	1757500596576846955	1757500596274857066	2026-04-20 16:19:57.519	\N
1757500597398930545	1757500597256324207	1757500596971111534	2026-04-20 16:19:57.6	\N
\.


--
-- Data for Name: card_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.card_membership (id, card_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: card_subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comment (id, card_id, user_id, text, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.config (id, created_at, updated_at, smtp_host, smtp_port, smtp_name, smtp_secure, smtp_tls_reject_unauthorized, smtp_user, smtp_password, smtp_from) FROM stdin;
1	2026-04-20 12:44:40.895	\N	\N	\N	\N	f	t	\N	\N	\N
\.


--
-- Data for Name: custom_field; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_field (id, base_custom_field_group_id, custom_field_group_id, "position", name, show_on_front_of_card, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: custom_field_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_field_group (id, board_id, card_id, base_custom_field_group_id, "position", name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: custom_field_value; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_field_value (id, card_id, custom_field_group_id, custom_field_id, content, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: identity_provider_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.identity_provider_user (id, user_id, issuer, sub, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: internal_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.internal_config (id, storage_limit, active_users_limit, is_initialized, created_at, updated_at) FROM stdin;
1	\N	\N	t	2026-04-20 12:44:40.975	2026-04-20 13:38:46.796
\.


--
-- Data for Name: label; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.label (id, board_id, "position", name, color, created_at, updated_at) FROM stdin;
1757500533989443347	1757500532622100233	65535	central-auth	berry-red	2026-04-20 16:19:50.041	\N
1757500534937356055	1757500532622100233	131070	dashboard	pumpkin-orange	2026-04-20 16:19:50.154	\N
1757500535818159899	1757500532622100233	196605	import-export	lagoon-blue	2026-04-20 16:19:50.259	\N
1757500536606689055	1757500532622100233	262140	map-mvp	pink-tulip	2026-04-20 16:19:50.354	\N
1757500537479104291	1757500532622100233	327675	memories-integration	light-mud	2026-04-20 16:19:50.458	\N
1757500540373174067	1757500538502514473	65535	auxiliary-signals-harvesting	berry-red	2026-04-20 16:19:50.802	\N
1757500541161703223	1757500538502514473	131070	map-reconciliation-pipeline	pumpkin-orange	2026-04-20 16:19:50.896	\N
1757500542503880510	1757500538502514473	196605	safe-import-governance	lagoon-blue	2026-04-20 16:19:51.056	\N
1757500543275632450	1757500538502514473	262140	structured-workitem-collection	pink-tulip	2026-04-20 16:19:51.149	\N
1757500545716717394	1757500544366151496	65535	control-plane-node	berry-red	2026-04-20 16:19:51.44	\N
1757500546429749078	1757500544366151496	131070	dns-update-engine	pumpkin-orange	2026-04-20 16:19:51.524	\N
1757500547461547866	1757500544366151496	196605	health-checks	lagoon-blue	2026-04-20 16:19:51.647	\N
1757500548409460574	1757500544366151496	262140	wg-priority-checks	pink-tulip	2026-04-20 16:19:51.76	\N
1757500550733105006	1757500549374150500	65535	chat-runtime	berry-red	2026-04-20 16:19:52.037	\N
1757500551496468338	1757500549374150500	131070	model-routing	pumpkin-orange	2026-04-20 16:19:52.128	\N
1757500552243054454	1757500549374150500	196605	serving-nodes	lagoon-blue	2026-04-20 16:19:52.217	\N
1757500554583476102	1757500553190967164	65535	markspanel	berry-red	2026-04-20 16:19:52.494	\N
1757500557670483859	1757500553190967164	131070	peer-lifecycle	pumpkin-orange	2026-04-20 16:19:52.865	\N
1757500558937163671	1757500553190967164	196605	tunnel-health	lagoon-blue	2026-04-20 16:19:53.016	\N
1757500560405170078	1757500553190967164	262140	wg-concentrator	pink-tulip	2026-04-20 16:19:53.19	\N
1757500562988861358	1757500561621518244	65535	command-queue	berry-red	2026-04-20 16:19:53.498	\N
1757500564448479157	1757500561621518244	131070	heartbeat	pumpkin-orange	2026-04-20 16:19:53.673	\N
1757500565438334905	1757500561621518244	196605	telemetry	lagoon-blue	2026-04-20 16:19:53.79	\N
1757500567610984393	1757500566369470399	65535	automation-runtime	berry-red	2026-04-20 16:19:54.049	\N
1757500569037047760	1757500566369470399	131070	human-memory-map-integration	pumpkin-orange	2026-04-20 16:19:54.22	\N
1757500569842354132	1757500566369470399	196605	persistent-memories	lagoon-blue	2026-04-20 16:19:54.316	\N
1757500570555385816	1757500566369470399	262140	session-memory	pink-tulip	2026-04-20 16:19:54.4	\N
1757500572870641640	1757500571570407390	65535	human-memory	berry-red	2026-04-20 16:19:54.676	\N
1757500573592061932	1757500571570407390	131070	persistent-memories	pumpkin-orange	2026-04-20 16:19:54.762	\N
1757500574296705008	1757500571570407390	196605	session-memory	lagoon-blue	2026-04-20 16:19:54.846	\N
1757500576578405376	1757500575244617718	65535	auth	berry-red	2026-04-20 16:19:55.118	\N
1757500577450820612	1757500575244617718	131070	dashboard	pumpkin-orange	2026-04-20 16:19:55.222	\N
1757500578189018120	1757500575244617718	196605	operator-workflows	lagoon-blue	2026-04-20 16:19:55.31	\N
1757500580579771416	1757500579111765006	65535	backup	berry-red	2026-04-20 16:19:55.595	\N
1757500581292803100	1757500579111765006	131070	inventory	pumpkin-orange	2026-04-20 16:19:55.68	\N
1757500582106498080	1757500579111765006	196605	monitor	lagoon-blue	2026-04-20 16:19:55.777	\N
1757500582978913316	1757500579111765006	262140	services	pink-tulip	2026-04-20 16:19:55.881	\N
1757500585252226100	1757500584044266538	65535	app-catalog	berry-red	2026-04-20 16:19:56.152	\N
1757500585990423608	1757500584044266538	131070	chat-ops	pumpkin-orange	2026-04-20 16:19:56.234	\N
1757500589194871877	1757500584044266538	196605	provisioning	lagoon-blue	2026-04-20 16:19:56.623	\N
1757500589941457993	1757500584044266538	262140	tenant-management	pink-tulip	2026-04-20 16:19:56.711	\N
1757500592390931545	1757500590981645391	65535	geral	berry-red	2026-04-20 16:19:57.004	\N
1757500593858937952	1757500590981645391	131070	integration	pumpkin-orange	2026-04-20 16:19:57.179	\N
1757500596274857066	1757500590981645391	196605	orchestration	lagoon-blue	2026-04-20 16:19:57.467	\N
1757500596971111534	1757500590981645391	262140	taxonomy	pink-tulip	2026-04-20 16:19:57.549	\N
\.


--
-- Data for Name: list; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.list (id, board_id, type, "position", name, color, created_at, updated_at) FROM stdin;
1757420994751890439	1757420994668004357	archive	\N	\N	\N	2026-04-20 13:41:48.224	\N
1757420994760279048	1757420994668004357	trash	\N	\N	\N	2026-04-20 13:41:48.224	\N
1757421403520369673	1757420994668004357	active	65536	BackLogs	\N	2026-04-20 13:42:36.95	\N
1757421491625919498	1757420994668004357	active	131072	Avanço 1	\N	2026-04-20 13:42:47.454	\N
1757500532655654667	1757500532622100233	archive	\N	\N	\N	2026-04-20 16:19:49.882	\N
1757500532664043276	1757500532622100233	trash	\N	\N	\N	2026-04-20 16:19:49.882	\N
1757500532991198989	1757500532622100233	active	65535	BackLogs	\N	2026-04-20 16:19:49.922	\N
1757500533091862286	1757500532622100233	active	131070	To Do	\N	2026-04-20 16:19:49.934	\N
1757500533184136975	1757500532622100233	active	196605	Doing	\N	2026-04-20 16:19:49.945	\N
1757500533276411664	1757500532622100233	active	262140	Review	\N	2026-04-20 16:19:49.956	\N
1757500533360297745	1757500532622100233	active	327675	Blocked	\N	2026-04-20 16:19:49.966	\N
1757500533452572434	1757500532622100233	active	393210	Done	\N	2026-04-20 16:19:49.977	\N
1757500538527680299	1757500538502514473	archive	\N	\N	\N	2026-04-20 16:19:50.583	\N
1757500538527680300	1757500538502514473	trash	\N	\N	\N	2026-04-20 16:19:50.583	\N
1757500538779338541	1757500538502514473	active	65535	BackLogs	\N	2026-04-20 16:19:50.612	\N
1757500538896779054	1757500538502514473	active	131070	To Do	\N	2026-04-20 16:19:50.626	\N
1757500538997442351	1757500538502514473	active	196605	Doing	\N	2026-04-20 16:19:50.638	\N
1757500539123271472	1757500538502514473	active	262140	Review	\N	2026-04-20 16:19:50.653	\N
1757500539307820849	1757500538502514473	active	327675	Blocked	\N	2026-04-20 16:19:50.675	\N
1757500561655072678	1757500561621518244	archive	\N	\N	\N	2026-04-20 16:19:53.34	\N
1757500561655072679	1757500561621518244	trash	\N	\N	\N	2026-04-20 16:19:53.34	\N
1757500561915119528	1757500561621518244	active	65535	BackLogs	\N	2026-04-20 16:19:53.37	\N
1757500562024171433	1757500561621518244	active	131070	To Do	\N	2026-04-20 16:19:53.384	\N
1757500562124834730	1757500561621518244	active	196605	Doing	\N	2026-04-20 16:19:53.396	\N
1757500562217109419	1757500561621518244	active	262140	Review	\N	2026-04-20 16:19:53.407	\N
1757500562309384108	1757500561621518244	active	327675	Blocked	\N	2026-04-20 16:19:53.417	\N
1757500562401658797	1757500561621518244	active	393210	Done	\N	2026-04-20 16:19:53.428	\N
1757500571595573216	1757500571570407390	archive	\N	\N	\N	2026-04-20 16:19:54.524	\N
1757500571595573217	1757500571570407390	trash	\N	\N	\N	2026-04-20 16:19:54.524	\N
1757500571805288418	1757500571570407390	active	65535	BackLogs	\N	2026-04-20 16:19:54.549	\N
1757500571897563107	1757500571570407390	active	131070	To Do	\N	2026-04-20 16:19:54.56	\N
1757500572023392228	1757500571570407390	active	196605	Doing	\N	2026-04-20 16:19:54.576	\N
1757500572124055525	1757500571570407390	active	262140	Review	\N	2026-04-20 16:19:54.587	\N
1757500572216330214	1757500571570407390	active	327675	Blocked	\N	2026-04-20 16:19:54.599	\N
1757500572316993511	1757500571570407390	active	393210	Done	\N	2026-04-20 16:19:54.611	\N
1757500579128542224	1757500579111765006	archive	\N	\N	\N	2026-04-20 16:19:55.423	\N
1757500579128542225	1757500579111765006	trash	\N	\N	\N	2026-04-20 16:19:55.423	\N
1757500579371811858	1757500579111765006	active	65535	BackLogs	\N	2026-04-20 16:19:55.452	\N
1757500579464086547	1757500579111765006	active	131070	To Do	\N	2026-04-20 16:19:55.463	\N
1757500579573138452	1757500579111765006	active	196605	Doing	\N	2026-04-20 16:19:55.475	\N
1757500579673801749	1757500579111765006	active	262140	Review	\N	2026-04-20 16:19:55.488	\N
1757500579808019478	1757500579111765006	active	327675	Blocked	\N	2026-04-20 16:19:55.504	\N
1757500579900294167	1757500579111765006	active	393210	Done	\N	2026-04-20 16:19:55.514	\N
1757500584077820972	1757500584044266538	archive	\N	\N	\N	2026-04-20 16:19:56.012	\N
1757500584077820973	1757500584044266538	trash	\N	\N	\N	2026-04-20 16:19:56.012	\N
1757500584295924782	1757500584044266538	active	65535	BackLogs	\N	2026-04-20 16:19:56.038	\N
1757500584396588079	1757500584044266538	active	131070	To Do	\N	2026-04-20 16:19:56.05	\N
1757500584480474160	1757500584044266538	active	196605	Doing	\N	2026-04-20 16:19:56.06	\N
1757500584597914673	1757500584044266538	active	262140	Review	\N	2026-04-20 16:19:56.074	\N
1757500584690189362	1757500584044266538	active	327675	Blocked	\N	2026-04-20 16:19:56.086	\N
1757500584799241267	1757500584044266538	active	393210	Done	\N	2026-04-20 16:19:56.098	\N
1757500539618199346	1757500538502514473	active	393210	Done	\N	2026-04-20 16:19:50.706	\N
1757500544399705930	1757500544366151496	archive	\N	\N	\N	2026-04-20 16:19:51.282	\N
1757500544399705931	1757500544366151496	trash	\N	\N	\N	2026-04-20 16:19:51.282	\N
1757500544676529996	1757500544366151496	active	65535	BackLogs	\N	2026-04-20 16:19:51.316	\N
1757500544802359117	1757500544366151496	active	131070	To Do	\N	2026-04-20 16:19:51.33	\N
1757500544919799630	1757500544366151496	active	196605	Doing	\N	2026-04-20 16:19:51.344	\N
1757500545028851535	1757500544366151496	active	262140	Review	\N	2026-04-20 16:19:51.357	\N
1757500545129514832	1757500544366151496	active	327675	Blocked	\N	2026-04-20 16:19:51.369	\N
1757500545255343953	1757500544366151496	active	393210	Done	\N	2026-04-20 16:19:51.385	\N
1757500549407704934	1757500549374150500	archive	\N	\N	\N	2026-04-20 16:19:51.88	\N
1757500549416093543	1757500549374150500	trash	\N	\N	\N	2026-04-20 16:19:51.88	\N
1757500549692917608	1757500549374150500	active	65535	BackLogs	\N	2026-04-20 16:19:51.914	\N
1757500549793580905	1757500549374150500	active	131070	To Do	\N	2026-04-20 16:19:51.925	\N
1757500549902632810	1757500549374150500	active	196605	Doing	\N	2026-04-20 16:19:51.938	\N
1757500549994907499	1757500549374150500	active	262140	Review	\N	2026-04-20 16:19:51.949	\N
1757500550187845484	1757500549374150500	active	327675	Blocked	\N	2026-04-20 16:19:51.972	\N
1757500550296897389	1757500549374150500	active	393210	Done	\N	2026-04-20 16:19:51.985	\N
1757500553216132990	1757500553190967164	archive	\N	\N	\N	2026-04-20 16:19:52.333	\N
1757500553216132991	1757500553190967164	trash	\N	\N	\N	2026-04-20 16:19:52.333	\N
1757500553543288704	1757500553190967164	active	65535	BackLogs	\N	2026-04-20 16:19:52.373	\N
1757500553652340609	1757500553190967164	active	131070	To Do	\N	2026-04-20 16:19:52.386	\N
1757500553753003906	1757500553190967164	active	196605	Doing	\N	2026-04-20 16:19:52.397	\N
1757500553845278595	1757500553190967164	active	262140	Review	\N	2026-04-20 16:19:52.408	\N
1757500553937553284	1757500553190967164	active	327675	Blocked	\N	2026-04-20 16:19:52.419	\N
1757500554021439365	1757500553190967164	active	393210	Done	\N	2026-04-20 16:19:52.429	\N
1757500566394636225	1757500566369470399	archive	\N	\N	\N	2026-04-20 16:19:53.904	\N
1757500566394636226	1757500566369470399	trash	\N	\N	\N	2026-04-20 16:19:53.904	\N
1757500566654683075	1757500566369470399	active	65535	BackLogs	\N	2026-04-20 16:19:53.936	\N
1757500566755346372	1757500566369470399	active	131070	To Do	\N	2026-04-20 16:19:53.947	\N
1757500566839232453	1757500566369470399	active	196605	Doing	\N	2026-04-20 16:19:53.958	\N
1757500566939895750	1757500566369470399	active	262140	Review	\N	2026-04-20 16:19:53.97	\N
1757500567032170439	1757500566369470399	active	327675	Blocked	\N	2026-04-20 16:19:53.98	\N
1757500567124445128	1757500566369470399	active	393210	Done	\N	2026-04-20 16:19:53.991	\N
1757500575269783544	1757500575244617718	archive	\N	\N	\N	2026-04-20 16:19:54.962	\N
1757500575269783545	1757500575244617718	trash	\N	\N	\N	2026-04-20 16:19:54.962	\N
1757500575487887354	1757500575244617718	active	65535	BackLogs	\N	2026-04-20 16:19:54.988	\N
1757500575622105083	1757500575244617718	active	131070	To Do	\N	2026-04-20 16:19:55.004	\N
1757500575739545596	1757500575244617718	active	196605	Doing	\N	2026-04-20 16:19:55.017	\N
1757500575848597501	1757500575244617718	active	262140	Review	\N	2026-04-20 16:19:55.032	\N
1757500575949260798	1757500575244617718	active	327675	Blocked	\N	2026-04-20 16:19:55.043	\N
1757500576066701311	1757500575244617718	active	393210	Done	\N	2026-04-20 16:19:55.057	\N
1757500590998422609	1757500590981645391	archive	\N	\N	\N	2026-04-20 16:19:56.838	\N
1757500591006811218	1757500590981645391	trash	\N	\N	\N	2026-04-20 16:19:56.838	\N
1757500591283635283	1757500590981645391	active	65535	BackLogs	\N	2026-04-20 16:19:56.871	\N
1757500591409464404	1757500590981645391	active	131070	To Do	\N	2026-04-20 16:19:56.887	\N
1757500591501739093	1757500590981645391	active	196605	Doing	\N	2026-04-20 16:19:56.898	\N
1757500591619179606	1757500590981645391	active	262140	Review	\N	2026-04-20 16:19:56.911	\N
1757500591728231511	1757500590981645391	active	327675	Blocked	\N	2026-04-20 16:19:56.924	\N
1757500591854060632	1757500590981645391	active	393210	Done	\N	2026-04-20 16:19:56.939	\N
1757490462526015233	1757490462484072191	archive	\N	\N	\N	2026-04-20 15:59:49.429	\N
1757490462534403842	1757490462484072191	trash	\N	\N	\N	2026-04-20 15:59:49.429	\N
\.


--
-- Data for Name: migration; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migration (id, name, batch, migration_time) FROM stdin;
1	20250228000022_version_2.js	1	2026-04-20 12:44:40.848+00
2	20250522151122_add_board_activity_log.js	1	2026-04-20 12:44:40.856+00
3	20250523131647_add_comments_counter.js	1	2026-04-20 12:44:40.862+00
4	20250603102521_canonicalize_locale_codes.js	1	2026-04-20 12:44:40.863+00
5	20250703122452_move_webhooks_configuration_from_environment_variable_to_ui.js	1	2026-04-20 12:44:40.873+00
6	20250708200908_persist_closed_state_per_card.js	1	2026-04-20 12:44:40.877+00
7	20250709160208_add_ability_to_link_tasks_to_cards.js	1	2026-04-20 12:44:40.881+00
8	20250721132312_add_ability_to_hide_completed_tasks.js	1	2026-04-20 12:44:40.885+00
9	20250728105713_add_legal_requirements.js	1	2026-04-20 12:44:40.897+00
10	20250820144730_track_storage_usage.js	1	2026-04-20 12:44:40.944+00
11	20250905101408_restore_toggleable_due_dates.js	1	2026-04-20 12:44:40.946+00
12	20250905205438_add_board_setting_to_expand_task_lists_by_default.js	1	2026-04-20 12:44:40.949+00
13	20250917123048_add_ability_to_configure_smtp_via_ui.js	1	2026-04-20 12:44:40.962+00
14	20251105104948_add_api_key_authentication.js	1	2026-04-20 12:44:40.966+00
15	20251121231641_rename_gin_indexes.js	1	2026-04-20 12:44:40.967+00
16	20260122093047_add_internal_runtime_configuration.js	1	2026-04-20 12:44:40.977+00
17	20260312000000_add_ability_to_display_card_ages.js	1	2026-04-20 12:44:40.98+00
\.


--
-- Data for Name: migration_lock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migration_lock (index, is_locked) FROM stdin;
1	0
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (id, user_id, creator_user_id, board_id, card_id, comment_id, action_id, type, data, is_read, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_service (id, user_id, board_id, url, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project (id, owner_project_manager_id, background_image_id, name, description, background_type, background_gradient, is_hidden, created_at, updated_at) FROM stdin;
1757420872932525059	1757420872982856708	\N	Teste	Teste	\N	\N	f	2026-04-20 13:41:33.698	2026-04-20 13:41:33.714
1757490424282351357	\N	\N	teste1	\N	\N	\N	f	2026-04-20 15:59:44.865	\N
1757500532269778695	1757500532286555912	\N	Map Project	\N	\N	\N	f	2026-04-20 16:19:49.832	2026-04-20 16:19:49.841
1757500538183747367	1757500538200524584	\N	Work360 Integration	\N	\N	\N	f	2026-04-20 16:19:50.542	2026-04-20 16:19:50.545
1757500544022218566	1757500544038995783	\N	Cloudflare DNS Failover	\N	\N	\N	f	2026-04-20 16:19:51.238	2026-04-20 16:19:51.241
1757500549072160610	1757500549088937827	\N	Chat Marks	\N	\N	\N	f	2026-04-20 16:19:51.84	2026-04-20 16:19:51.843
1757500552905754490	1757500552914143099	\N	Zero Trust Network	\N	\N	\N	f	2026-04-20 16:19:52.296	2026-04-20 16:19:52.299
1757500561252419490	1757500561260808099	\N	Guardian Control Plane	\N	\N	\N	f	2026-04-20 16:19:53.291	2026-04-20 16:19:53.294
1757500566109423549	1757500566117812158	\N	MarksCode	\N	\N	\N	f	2026-04-20 16:19:53.87	2026-04-20 16:19:53.873
1757500571276806108	1757500571293583325	\N	Memories	\N	\N	\N	f	2026-04-20 16:19:54.487	2026-04-20 16:19:54.491
1757500574992959476	1757500575001348085	\N	MarksPanel	\N	\N	\N	f	2026-04-20 16:19:54.929	2026-04-20 16:19:54.932
1757500578851718156	1757500578860106765	\N	Cluster Operations	\N	\N	\N	f	2026-04-20 16:19:55.389	2026-04-20 16:19:55.392
1757500583750665256	1757500583759053865	\N	SaaS Hub	\N	\N	\N	f	2026-04-20 16:19:55.973	2026-04-20 16:19:55.976
1757500590646101069	1757500590654489678	\N	Ecosystem Marks	\N	\N	\N	f	2026-04-20 16:19:56.795	2026-04-20 16:19:56.798
\.


--
-- Data for Name: project_favorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_favorite (id, project_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: project_manager; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_manager (id, project_id, user_id, created_at, updated_at) FROM stdin;
1757420872982856708	1757420872932525059	1757414626749842433	2026-04-20 13:41:33.709	\N
1757490424315905790	1757490424282351357	1757414626749842433	2026-04-20 15:59:44.874	\N
1757500532286555912	1757500532269778695	1757414626749842433	2026-04-20 16:19:49.838	\N
1757500538200524584	1757500538183747367	1757414626749842433	2026-04-20 16:19:50.543	\N
1757500544038995783	1757500544022218566	1757414626749842433	2026-04-20 16:19:51.239	\N
1757500549088937827	1757500549072160610	1757414626749842433	2026-04-20 16:19:51.841	\N
1757500552914143099	1757500552905754490	1757414626749842433	2026-04-20 16:19:52.297	\N
1757500561260808099	1757500561252419490	1757414626749842433	2026-04-20 16:19:53.293	\N
1757500566117812158	1757500566109423549	1757414626749842433	2026-04-20 16:19:53.871	\N
1757500571293583325	1757500571276806108	1757414626749842433	2026-04-20 16:19:54.489	\N
1757500575001348085	1757500574992959476	1757414626749842433	2026-04-20 16:19:54.93	\N
1757500578860106765	1757500578851718156	1757414626749842433	2026-04-20 16:19:55.39	\N
1757500583759053865	1757500583750665256	1757414626749842433	2026-04-20 16:19:55.974	\N
1757500590654489678	1757500590646101069	1757414626749842433	2026-04-20 16:19:56.797	\N
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.session (id, user_id, access_token, http_only_token, remote_address, user_agent, created_at, updated_at, deleted_at, pending_token) FROM stdin;
1757472392499692557	1757414626749842433	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjMxODEwODY0LTg0ZDUtNGMxMi05MDIzLWMxOWRhM2E0M2VlYSJ9.eyJpYXQiOjE3NzY2OTg2MzUsImV4cCI6MTgwODIzNDYzNSwic3ViIjoiMTc1NzQxNDYyNjc0OTg0MjQzMyJ9.1J6s_EsOuuYfGSjSy0vDbxRbdwbR5NEuqHUpvSap86k	\N	172.19.0.1	python-requests/2.31.0	2026-04-20 15:23:55.308	\N	\N	\N
1757419393467286530	1757414626749842433	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImNkODgyNjM3LTJmNWYtNDM4MS05ZjY3LTMxYTBkMmJiOGRmZiJ9.eyJpYXQiOjE3NzY2OTIzMjYsImV4cCI6MTgwODIyODMyNiwic3ViIjoiMTc1NzQxNDYyNjc0OTg0MjQzMyJ9.QpYRwWg2dtuwDRGxfO-ReXMyj-lUILF4RjtZbEbceuo	44c20684-574c-4245-8602-7b86f9651905	172.19.0.1	Mozilla/5.0 (X11; Linux x86_64; rv:149.0) Gecko/20100101 Firefox/149.0	2026-04-20 13:38:37.328	2026-04-20 15:41:04.659	2026-04-20 15:41:04.657	\N
1757482211348579561	1757414626749842433	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImNkNTZhOGY3LTYzOWQtNDFhNS1hMTgzLTk2MmNkM2UyMTQ1NiJ9.eyJpYXQiOjE3NzY2OTk4MDUsImV4cCI6MTgwODIzNTgwNSwic3ViIjoiMTc1NzQxNDYyNjc0OTg0MjQzMyJ9.fQsI209T1_Q_wnkMY36e72XvdjH_oANoklvSl9FPzlQ	82c9e6fd-00da-499b-a5fc-d68d353c02df	172.19.0.1	Mozilla/5.0 (X11; Linux x86_64; rv:149.0) Gecko/20100101 Firefox/149.0	2026-04-20 15:43:25.807	\N	\N	\N
1757517049271157874	1757414626749842433	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImIwOWY1NzMzLTQyOGMtNDNhZC1hNTM1LWUwMTA5M2QyZmFkYSJ9.eyJpYXQiOjE3NzY3MDM5NTgsImV4cCI6MTgwODIzOTk1OCwic3ViIjoiMTc1NzQxNDYyNjc0OTg0MjQzMyJ9.ZG3rQBcZtOBkjWprgpBbDb8TBdW2tkDU5spi27JCCL8	27c58c98-cadc-4590-9ccf-c5504050303e	172.19.0.1	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1	2026-04-20 16:52:38.81	\N	\N	\N
\.


--
-- Data for Name: storage_usage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage_usage (id, total, user_avatars, background_images, attachments, created_at, updated_at) FROM stdin;
1	0	0	0	0	2026-04-20 12:44:40.474283	2026-04-20 16:19:34.178
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task (id, task_list_id, assignee_user_id, "position", name, is_completed, created_at, updated_at, linked_card_id) FROM stdin;
\.


--
-- Data for Name: task_list; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task_list (id, card_id, "position", name, show_on_front_of_card, created_at, updated_at, hide_completed_tasks) FROM stdin;
\.


--
-- Data for Name: uploaded_file; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.uploaded_file (id, references_total, created_at, updated_at, type, mime_type, size) FROM stdin;
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_account (id, email, password, role, name, username, avatar, phone, organization, language, subscribe_to_own_cards, subscribe_to_card_when_commenting, turn_off_recent_card_highlighting, enable_favorites_by_default, default_editor_mode, default_home_view, default_projects_order, is_sso_user, is_deactivated, created_at, updated_at, password_changed_at, terms_signature, terms_accepted_at, api_key_prefix, api_key_hash, api_key_created_at) FROM stdin;
1757414626749842433	admin@marks.ia.br	$2b$10$nmb/eqZdIa9hzxzPT/bvUOea3kPJRD79ZfnHG42MerQGku7QpLLES	admin	Marks Admin	admin	\N	\N	\N	pt-BR	f	t	f	t	wysiwyg	groupedProjects	byDefault	f	f	2026-04-20 13:29:09.089	2026-04-20 13:38:46.77	\N	03f07fa4887405919f0a569871c5bed69e5fc2e7045b186145dbd8ca09c2351a	2026-04-20 13:38:46.762	\N	\N	\N
\.


--
-- Data for Name: webhook; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.webhook (id, board_id, name, url, access_token, events, excluded_events, created_at, updated_at) FROM stdin;
\.


--
-- Name: migration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migration_id_seq', 17, true);


--
-- Name: migration_lock_index_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migration_lock_index_seq', 1, true);


--
-- Name: next_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.next_id_seq', 2163, true);


--
-- Name: action action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.action
    ADD CONSTRAINT action_pkey PRIMARY KEY (id);


--
-- Name: attachment attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attachment
    ADD CONSTRAINT attachment_pkey PRIMARY KEY (id);


--
-- Name: background_image background_image_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.background_image
    ADD CONSTRAINT background_image_pkey PRIMARY KEY (id);


--
-- Name: base_custom_field_group base_custom_field_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_custom_field_group
    ADD CONSTRAINT base_custom_field_group_pkey PRIMARY KEY (id);


--
-- Name: board_membership board_membership_board_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.board_membership
    ADD CONSTRAINT board_membership_board_id_user_id_unique UNIQUE (board_id, user_id);


--
-- Name: board_membership board_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.board_membership
    ADD CONSTRAINT board_membership_pkey PRIMARY KEY (id);


--
-- Name: board board_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.board
    ADD CONSTRAINT board_pkey PRIMARY KEY (id);


--
-- Name: board_subscription board_subscription_board_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.board_subscription
    ADD CONSTRAINT board_subscription_board_id_user_id_unique UNIQUE (board_id, user_id);


--
-- Name: board_subscription board_subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.board_subscription
    ADD CONSTRAINT board_subscription_pkey PRIMARY KEY (id);


--
-- Name: card_label card_label_card_id_label_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_label
    ADD CONSTRAINT card_label_card_id_label_id_unique UNIQUE (card_id, label_id);


--
-- Name: card_label card_label_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_label
    ADD CONSTRAINT card_label_pkey PRIMARY KEY (id);


--
-- Name: card_membership card_membership_card_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_membership
    ADD CONSTRAINT card_membership_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_membership card_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_membership
    ADD CONSTRAINT card_membership_pkey PRIMARY KEY (id);


--
-- Name: card card_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card
    ADD CONSTRAINT card_pkey PRIMARY KEY (id);


--
-- Name: card_subscription card_subscription_card_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_subscription
    ADD CONSTRAINT card_subscription_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_subscription card_subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.card_subscription
    ADD CONSTRAINT card_subscription_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: custom_field_group custom_field_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_field_group
    ADD CONSTRAINT custom_field_group_pkey PRIMARY KEY (id);


--
-- Name: custom_field custom_field_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_field
    ADD CONSTRAINT custom_field_pkey PRIMARY KEY (id);


--
-- Name: custom_field_value custom_field_value_card_id_custom_field_group_id_custom_field_i; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_field_value
    ADD CONSTRAINT custom_field_value_card_id_custom_field_group_id_custom_field_i UNIQUE (card_id, custom_field_group_id, custom_field_id);


--
-- Name: custom_field_value custom_field_value_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_field_value
    ADD CONSTRAINT custom_field_value_pkey PRIMARY KEY (id);


--
-- Name: identity_provider_user identity_provider_user_issuer_sub_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_user
    ADD CONSTRAINT identity_provider_user_issuer_sub_unique UNIQUE (issuer, sub);


--
-- Name: identity_provider_user identity_provider_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_user
    ADD CONSTRAINT identity_provider_user_pkey PRIMARY KEY (id);


--
-- Name: internal_config internal_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.internal_config
    ADD CONSTRAINT internal_config_pkey PRIMARY KEY (id);


--
-- Name: label label_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: list list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.list
    ADD CONSTRAINT list_pkey PRIMARY KEY (id);


--
-- Name: migration_lock migration_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_lock
    ADD CONSTRAINT migration_lock_pkey PRIMARY KEY (index);


--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: notification_service notification_service_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_service
    ADD CONSTRAINT notification_service_pkey PRIMARY KEY (id);


--
-- Name: project_favorite project_favorite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_favorite
    ADD CONSTRAINT project_favorite_pkey PRIMARY KEY (id);


--
-- Name: project_favorite project_favorite_project_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_favorite
    ADD CONSTRAINT project_favorite_project_id_user_id_unique UNIQUE (project_id, user_id);


--
-- Name: project_manager project_manager_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_manager
    ADD CONSTRAINT project_manager_pkey PRIMARY KEY (id);


--
-- Name: project_manager project_manager_project_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_manager
    ADD CONSTRAINT project_manager_project_id_user_id_unique UNIQUE (project_id, user_id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: session session_access_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_access_token_unique UNIQUE (access_token);


--
-- Name: session session_pending_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pending_token_unique UNIQUE (pending_token);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: storage_usage storage_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_usage
    ADD CONSTRAINT storage_usage_pkey PRIMARY KEY (id);


--
-- Name: task_list task_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_list
    ADD CONSTRAINT task_list_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: uploaded_file uploaded_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uploaded_file
    ADD CONSTRAINT uploaded_file_pkey PRIMARY KEY (id);


--
-- Name: user_account user_account_api_key_hash_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_api_key_hash_unique UNIQUE (api_key_hash);


--
-- Name: user_account user_account_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_email_unique UNIQUE (email);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_account user_account_username_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_username_unique EXCLUDE USING btree (username WITH =) WHERE ((username IS NOT NULL));


--
-- Name: webhook webhook_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT webhook_pkey PRIMARY KEY (id);


--
-- Name: action_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX action_board_id_index ON public.action USING btree (board_id);


--
-- Name: action_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX action_card_id_index ON public.action USING btree (card_id);


--
-- Name: action_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX action_user_id_index ON public.action USING btree (user_id);


--
-- Name: attachment_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attachment_card_id_index ON public.attachment USING btree (card_id);


--
-- Name: attachment_creator_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attachment_creator_user_id_index ON public.attachment USING btree (creator_user_id);


--
-- Name: background_image_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX background_image_project_id_index ON public.background_image USING btree (project_id);


--
-- Name: base_custom_field_group_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX base_custom_field_group_project_id_index ON public.base_custom_field_group USING btree (project_id);


--
-- Name: board_membership_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_membership_project_id_index ON public.board_membership USING btree (project_id);


--
-- Name: board_membership_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_membership_user_id_index ON public.board_membership USING btree (user_id);


--
-- Name: board_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_position_index ON public.board USING btree ("position");


--
-- Name: board_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_project_id_index ON public.board USING btree (project_id);


--
-- Name: board_subscription_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_subscription_user_id_index ON public.board_subscription USING btree (user_id);


--
-- Name: card_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_board_id_index ON public.card USING btree (board_id);


--
-- Name: card_creator_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_creator_user_id_index ON public.card USING btree (creator_user_id);


--
-- Name: card_description_gin_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_description_gin_index ON public.card USING gin (description public.gin_trgm_ops);


--
-- Name: card_label_label_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_label_label_id_index ON public.card_label USING btree (label_id);


--
-- Name: card_list_changed_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_list_changed_at_index ON public.card USING btree (list_changed_at);


--
-- Name: card_list_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_list_id_index ON public.card USING btree (list_id);


--
-- Name: card_membership_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_membership_user_id_index ON public.card_membership USING btree (user_id);


--
-- Name: card_name_gin_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_name_gin_index ON public.card USING gin (name public.gin_trgm_ops);


--
-- Name: card_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_position_index ON public.card USING btree ("position");


--
-- Name: card_subscription_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_subscription_user_id_index ON public.card_subscription USING btree (user_id);


--
-- Name: comment_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_card_id_index ON public.comment USING btree (card_id);


--
-- Name: comment_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comment_user_id_index ON public.comment USING btree (user_id);


--
-- Name: custom_field_base_custom_field_group_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_base_custom_field_group_id_index ON public.custom_field USING btree (base_custom_field_group_id);


--
-- Name: custom_field_custom_field_group_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_custom_field_group_id_index ON public.custom_field USING btree (custom_field_group_id);


--
-- Name: custom_field_group_base_custom_field_group_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_group_base_custom_field_group_id_index ON public.custom_field_group USING btree (base_custom_field_group_id);


--
-- Name: custom_field_group_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_group_board_id_index ON public.custom_field_group USING btree (board_id);


--
-- Name: custom_field_group_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_group_card_id_index ON public.custom_field_group USING btree (card_id);


--
-- Name: custom_field_group_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_group_position_index ON public.custom_field_group USING btree ("position");


--
-- Name: custom_field_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_position_index ON public.custom_field USING btree ("position");


--
-- Name: custom_field_value_custom_field_group_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_value_custom_field_group_id_index ON public.custom_field_value USING btree (custom_field_group_id);


--
-- Name: custom_field_value_custom_field_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX custom_field_value_custom_field_id_index ON public.custom_field_value USING btree (custom_field_id);


--
-- Name: identity_provider_user_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX identity_provider_user_user_id_index ON public.identity_provider_user USING btree (user_id);


--
-- Name: label_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX label_board_id_index ON public.label USING btree (board_id);


--
-- Name: label_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX label_position_index ON public.label USING btree ("position");


--
-- Name: list_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX list_board_id_index ON public.list USING btree (board_id);


--
-- Name: list_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX list_position_index ON public.list USING btree ("position");


--
-- Name: list_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX list_type_index ON public.list USING btree (type);


--
-- Name: notification_action_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_action_id_index ON public.notification USING btree (action_id);


--
-- Name: notification_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_card_id_index ON public.notification USING btree (card_id);


--
-- Name: notification_comment_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_comment_id_index ON public.notification USING btree (comment_id);


--
-- Name: notification_creator_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_creator_user_id_index ON public.notification USING btree (creator_user_id);


--
-- Name: notification_is_read_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_is_read_index ON public.notification USING btree (is_read);


--
-- Name: notification_service_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_service_board_id_index ON public.notification_service USING btree (board_id);


--
-- Name: notification_service_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_service_user_id_index ON public.notification_service USING btree (user_id);


--
-- Name: notification_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_user_id_index ON public.notification USING btree (user_id);


--
-- Name: project_favorite_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_favorite_user_id_index ON public.project_favorite USING btree (user_id);


--
-- Name: project_manager_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_manager_user_id_index ON public.project_manager USING btree (user_id);


--
-- Name: project_owner_project_manager_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_owner_project_manager_id_index ON public.project USING btree (owner_project_manager_id);


--
-- Name: session_remote_address_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX session_remote_address_index ON public.session USING btree (remote_address);


--
-- Name: session_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX session_user_id_index ON public.session USING btree (user_id);


--
-- Name: task_assignee_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_assignee_user_id_index ON public.task USING btree (assignee_user_id);


--
-- Name: task_linked_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_linked_card_id_index ON public.task USING btree (linked_card_id);


--
-- Name: task_list_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_list_card_id_index ON public.task_list USING btree (card_id);


--
-- Name: task_list_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_list_position_index ON public.task_list USING btree ("position");


--
-- Name: task_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_position_index ON public.task USING btree ("position");


--
-- Name: task_task_list_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_task_list_id_index ON public.task USING btree (task_list_id);


--
-- Name: uploaded_file_references_total_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uploaded_file_references_total_index ON public.uploaded_file USING btree (references_total);


--
-- Name: uploaded_file_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uploaded_file_type_index ON public.uploaded_file USING btree (type);


--
-- Name: user_account_is_deactivated_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_account_is_deactivated_index ON public.user_account USING btree (is_deactivated);


--
-- Name: user_account_role_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_account_role_index ON public.user_account USING btree (role);


--
-- Name: user_account_username_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_account_username_index ON public.user_account USING btree (username);


--
-- Name: webhook_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX webhook_board_id_index ON public.webhook USING btree (board_id);


--
-- PostgreSQL database dump complete
--

\unrestrict qdZc8cTTgcA8JxRHB1kHhY0xeHfihNkVar0SWnbtD3YxpGcnRJ0KHt7NbMVOU2c

