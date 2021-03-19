CREATE DATABASE recrutamento;

CREATE ROLE playground;
ALTER ROLE playground WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS ENCRYPTED PASSWORD 'dev123456';

-- Versão = PostgreSQL 10

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE public.tipo_cliente AS ENUM (
    'juridico', 'fisico', 'especial'
);
ALTER TYPE public.tipo_cliente OWNER TO brisamaster;

CREATE TYPE public.contrato_estado AS ENUM (
    'Em vigor', 'Desativado Temporario', 'Cancelado'
);
ALTER TYPE public.contrato_estado OWNER TO brisamaster;

CREATE FUNCTION public.tf_utils_setar_data_atualizacao() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE 
  tabela_raw TEXT; 
  tabela TEXT; 
  temp_mensagem TEXT;
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    NEW.data_atualizacao = now();
    RETURN NEW;
  ELSE 
  
    tabela_raw := replace(TG_TABLE_NAME, 't_', '');
    tabela := replace(tabela_raw, '_', ' ');
    temp_mensagem := 'Atributo data_atualizacao, atualização NãO autorizada para gatilhos diferentes de UPDATE para ('||tabela||') !!'; 
    RAISE EXCEPTION feature_not_supported USING HINT = temp_mensagem;

  END IF;
END;

$$;

ALTER FUNCTION public.tf_utils_setar_data_atualizacao() OWNER TO brisamaster;

GRANT EXECUTE ON FUNCTION public.tf_utils_setar_data_atualizacao() to playground;

CREATE TABLE public.t_cliente (
    id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    data_criacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    nome TEXT NOT NULL CHECK(char_length(nome) BETWEEN 3 AND 128) UNIQUE,
    data_remocao TIMESTAMP WITHOUT TIME ZONE,
    tipo public.tipo_cliente NOT NULL
);

ALTER TABLE public.t_cliente OWNER TO brisamaster;

GRANT SELECT, INSERT, UPDATE ON public.t_cliente TO playground;

REVOKE ALL ON TABLE public.t_cliente FROM public;

CREATE TRIGGER t_cliente_setar_data_atualizacao
  BEFORE UPDATE 
  ON public.t_cliente
  FOR EACH ROW
EXECUTE PROCEDURE public.tf_utils_setar_data_atualizacao();

CREATE TABLE public.t_endereco (
    id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    data_criacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    logradouro TEXT NOT NULL CHECK(char_length(logradouro) BETWEEN 3 AND 128),
    bairro TEXT NOT NULL CHECK(char_length(bairro) BETWEEN 3 AND 128),
    numero SMALLINT NOT NULL,
    data_remocao TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE public.t_endereco OWNER TO brisamaster;

GRANT SELECT, INSERT, UPDATE ON public.t_endereco TO playground;

REVOKE ALL ON TABLE public.t_endereco FROM public;

CREATE TRIGGER t_endereco_setar_data_atualizacao
  BEFORE UPDATE 
  ON public.t_endereco
  FOR EACH ROW
EXECUTE PROCEDURE public.tf_utils_setar_data_atualizacao();

CREATE TABLE public.t_ponto (
    id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    data_criacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    cliente_id UUID NOT NULL REFERENCES public.t_cliente (id), 
    endereco_id UUID NOT NULL REFERENCES public.t_endereco (id),
    data_remocao TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE public.t_ponto OWNER TO brisamaster;

GRANT SELECT, INSERT, UPDATE ON public.t_ponto TO playground;

REVOKE ALL ON TABLE public.t_ponto FROM public;

CREATE TRIGGER t_ponto_setar_data_atualizacao
  BEFORE UPDATE 
  ON public.t_ponto
  FOR EACH ROW
EXECUTE PROCEDURE public.tf_utils_setar_data_atualizacao();

ALTER TABLE public.t_ponto ADD CONSTRAINT t_ponto_client_ender_uq UNIQUE(cliente_id, endereco_id);

CREATE TABLE public.t_contrato (
    id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    data_criacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    ponto_id UUID NOT NULL REFERENCES public.t_ponto (id) UNIQUE, 
    estado public.contrato_estado NOT NULL,
    data_remocao TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE public.t_contrato OWNER TO brisamaster;

GRANT SELECT, INSERT, UPDATE ON public.t_contrato TO playground;

REVOKE ALL ON TABLE public.t_contrato FROM public;

CREATE TRIGGER t_contrato_setar_data_atualizacao
  BEFORE UPDATE 
  ON public.t_contrato
  FOR EACH ROW
EXECUTE PROCEDURE public.tf_utils_setar_data_atualizacao();

CREATE TABLE public.t_contrato_evento (
    id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    data_criacao TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data_atualizacao TIMESTAMP WITH TIME ZONE,
    contrato_id UUID NOT NULL REFERENCES public.t_contrato(id), 
    estado_anterior public.contrato_estado NOT NULL,
    estado_posterior public.contrato_estado NOT NULL
);

ALTER TABLE public.t_contrato_evento OWNER TO brisamaster;

GRANT SELECT, INSERT, UPDATE ON public.t_contrato_evento TO playground;

REVOKE ALL ON TABLE public.t_contrato_evento FROM public;

CREATE TRIGGER t_contrato_evento_setar_data_atualizacao
  BEFORE UPDATE 
  ON public.t_contrato_evento
  FOR EACH ROW
EXECUTE PROCEDURE public.tf_utils_setar_data_atualizacao();
