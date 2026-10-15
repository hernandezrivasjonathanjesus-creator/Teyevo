-- =======================================================================
-- BASE DE DATOS COMPLETA TEYEVO PARA SUPABASE (POSTGRESQL)
-- SISTEMA DE TRANSPORTE CON MÓDULO DE TAXI Y RUTA TURÍSTICO

-- =======================================================================

-- =======================================================================
-- 1. EXTENSIONES  EN SUPABASE
-- =======================================================================

-- Habilitar extensiones (ejecutar en Supabase SQL Editor)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

-- =======================================================================
-- 2. ELIMINACIÓN DE TABLAS (En orden inverso a dependencias)
-- =======================================================================

-- Módulo Turístico
DROP TABLE IF EXISTS public.historial_visitas_turisticas CASCADE;
DROP TABLE IF EXISTS public.calificaciones_puntos_turisticos CASCADE;
DROP TABLE IF EXISTS public.reservas_paquetes_turisticos CASCADE;
DROP TABLE IF EXISTS public.detalle_paquete_turistico CASCADE;
DROP TABLE IF EXISTS public.paquetes_turisticos CASCADE;
DROP TABLE IF EXISTS public.paradas_turisticas_itinerario CASCADE;
DROP TABLE IF EXISTS public.galeria_puntos_turisticos CASCADE;
DROP TABLE IF EXISTS public.puntos_turisticos CASCADE;
DROP TABLE IF EXISTS public.categorias_turisticas CASCADE;

-- Módulo Financiero
DROP TABLE IF EXISTS public.retenciones_impuestos CASCADE;
DROP TABLE IF EXISTS public.conciliacion_bancaria CASCADE;
DROP TABLE IF EXISTS public.pagos CASCADE;
DROP TABLE IF EXISTS public.facturas CASCADE;

-- Módulo de Soporte
DROP TABLE IF EXISTS public.historial_tickets CASCADE;
DROP TABLE IF EXISTS public.respuestas_ticket CASCADE;
DROP TABLE IF EXISTS public.sla_configuracion CASCADE;
DROP TABLE IF EXISTS public.tickets_soporte CASCADE;

-- Módulo de Seguridad
DROP TABLE IF EXISTS public.rol_permisos CASCADE;
DROP TABLE IF EXISTS public.permisos_detallados CASCADE;
DROP TABLE IF EXISTS public.auditoria_cambios CASCADE;
DROP TABLE IF EXISTS public.intentos_acceso CASCADE;
DROP TABLE IF EXISTS public.sesiones_activas CASCADE;

-- Módulo de Marketing
DROP TABLE IF EXISTS public.usuarios_segmentos CASCADE;
DROP TABLE IF EXISTS public.segmentos_clientes CASCADE;
DROP TABLE IF EXISTS public.uso_cupones CASCADE;
DROP TABLE IF EXISTS public.cupones CASCADE;

-- Módulo de Notificaciones
DROP TABLE IF EXISTS public.notificaciones CASCADE;
DROP TABLE IF EXISTS public.suscripciones_usuario CASCADE;
DROP TABLE IF EXISTS public.plantillas_notificaciones CASCADE;

-- Módulo de Flota
DROP TABLE IF EXISTS public.asignaciones_vehiculo_conductor CASCADE;
DROP TABLE IF EXISTS public.historial_km_vehiculo CASCADE;
DROP TABLE IF EXISTS public.mantenimiento_vehiculos CASCADE;
DROP TABLE IF EXISTS public.tipos_vehiculo CASCADE;

-- Módulo de Geolocalización
DROP TABLE IF EXISTS public.alertas_geograficas CASCADE;
DROP TABLE IF EXISTS public.rutas_recorridas CASCADE;
DROP TABLE IF EXISTS public.zonas_geograficas CASCADE;
DROP TABLE IF EXISTS public.tracking_vehiculos CASCADE;

-- Módulo de Inventario
DROP TABLE IF EXISTS public.movimientos_inventario CASCADE;
DROP TABLE IF EXISTS public.productos_inventario CASCADE;

-- Módulo de Reportes
DROP TABLE IF EXISTS public.kpi_tiempo_real CASCADE;
DROP TABLE IF EXISTS public.metricas_satisfaccion CASCADE;
DROP TABLE IF EXISTS public.reportes_diarios CASCADE;

-- Módulo de Configuración
DROP TABLE IF EXISTS public.configuracion_sistema CASCADE;

-- Tablas Operativas
DROP TABLE IF EXISTS public.reservas CASCADE;
DROP TABLE IF EXISTS public.categorias_asiento CASCADE;
DROP TABLE IF EXISTS public.tipos_incidentes CASCADE;
DROP TABLE IF EXISTS public.tipos_documentos CASCADE;

-- Tablas Originales
DROP TABLE IF EXISTS public.metricas_publicidad CASCADE;
DROP TABLE IF EXISTS public.banners CASCADE;
DROP TABLE IF EXISTS public.campanas CASCADE;
DROP TABLE IF EXISTS public.anunciantes CASCADE;
DROP TABLE IF EXISTS public.alertas_automaticas CASCADE;
DROP TABLE IF EXISTS public.mensajes_chat CASCADE;
DROP TABLE IF EXISTS public.canjes_puntos CASCADE;
DROP TABLE IF EXISTS public.reglas_puntos CASCADE;
DROP TABLE IF EXISTS public.programa_referidos CASCADE;
DROP TABLE IF EXISTS public.billetera_puntos CASCADE;
DROP TABLE IF EXISTS public.favoritos CASCADE;
DROP TABLE IF EXISTS public.viajes_recurrentes CASCADE;
DROP TABLE IF EXISTS public.preferencias_pasajero CASCADE;
DROP TABLE IF EXISTS public.solicitudes_cancelacion CASCADE;
DROP TABLE IF EXISTS public.politicas_cancelacion CASCADE;
DROP TABLE IF EXISTS public.logistica_inversa CASCADE;
DROP TABLE IF EXISTS public.envios CASCADE;
DROP TABLE IF EXISTS public.costos_operativos_itinerario CASCADE;
DROP TABLE IF EXISTS public.registro_descansos CASCADE;
DROP TABLE IF EXISTS public.detalle_asientos_itinerario CASCADE;
DROP TABLE IF EXISTS public.paradas_intermedias CASCADE;
DROP TABLE IF EXISTS public.itinerarios CASCADE;
DROP TABLE IF EXISTS public.precios_multimoneda CASCADE;
DROP TABLE IF EXISTS public.tipos_cambio CASCADE;
DROP TABLE IF EXISTS public.rutas CASCADE;
DROP TABLE IF EXISTS public.conductores CASCADE;
DROP TABLE IF EXISTS public.vehiculos CASCADE;
DROP TABLE IF EXISTS public.historial_validaciones_doc CASCADE;
DROP TABLE IF EXISTS public.instrumentos_pago CASCADE;
DROP TABLE IF EXISTS public.historial_transacciones CASCADE;
DROP TABLE IF EXISTS public.historial_viajes CASCADE;
DROP TABLE IF EXISTS public.logs_actividad CASCADE;
DROP TABLE IF EXISTS public.tokens_sesion CASCADE;
DROP TABLE IF EXISTS public.recuperacion_contrasena CASCADE;
DROP TABLE IF EXISTS public.usuarios CASCADE;
DROP TABLE IF EXISTS public.ciudades CASCADE;
DROP TABLE IF EXISTS public.estados CASCADE;
DROP TABLE IF EXISTS public.paises CASCADE;
DROP TABLE IF EXISTS public.monedas CASCADE;
DROP TABLE IF EXISTS public.roles_permisos CASCADE;

-- =======================================================================
-- 3. CREACIÓN DE TABLAS CATÁLOGO
-- =======================================================================

-- 3.1 Monedas
CREATE TABLE public.monedas (
    id_moneda SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    simbolo VARCHAR(5) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.2 Roles y Permisos
CREATE TABLE public.roles_permisos (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    permisos JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.3 Países
CREATE TABLE public.paises (
    id_pais SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    codigo_iso2 CHAR(2) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.4 Estados
CREATE TABLE public.estados (
    id_estado SERIAL PRIMARY KEY,
    id_pais INTEGER NOT NULL REFERENCES public.paises(id_pais),
    nombre VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.5 Ciudades
CREATE TABLE public.ciudades (
    id_ciudad SERIAL PRIMARY KEY,
    id_estado INTEGER NOT NULL REFERENCES public.estados(id_estado),
    nombre VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(20) NULL,
    latitud DECIMAL(10,8) NULL,
    longitud DECIMAL(11,8) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.6 Categorías de Asientos
CREATE TABLE public.categorias_asiento (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    factor_precio DECIMAL(3,2) NOT NULL DEFAULT 1.00,
    descripcion VARCHAR(200) NULL,
    icono VARCHAR(50) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.7 Tipos de Incidentes
CREATE TABLE public.tipos_incidentes (
    id_tipo_incidente SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NULL,
    gravedad VARCHAR(20) NOT NULL CHECK (gravedad IN ('BAJA', 'MEDIA', 'ALTA', 'CRITICA')),
    tiempo_resolucion_esperado_minutos INTEGER NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.8 Tipos de Documentos
CREATE TABLE public.tipos_documentos (
    id_tipo_documento SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    codigo VARCHAR(10) NOT NULL,
    requiere_validacion BOOLEAN NOT NULL DEFAULT TRUE,
    descripcion VARCHAR(200) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.9 Tipos de Vehículo
CREATE TABLE public.tipos_vehiculo (
    id_tipo SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NULL,
    capacidad_pasajeros INTEGER NOT NULL,
    capacidad_equipaje_kg DECIMAL(8,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 4. TABLA USUARIOS (CON AUTENTICACIÓN SUPABASE)
-- =======================================================================

CREATE TABLE public.usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_rol INTEGER NOT NULL REFERENCES public.roles_permisos(id_rol),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL,
    numero_identidad VARCHAR(20) NOT NULL UNIQUE,
    fecha_nacimiento DATE NOT NULL,
    edad_validada BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ultimo_acceso TIMESTAMPTZ NULL,
    estado_cuenta VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado_cuenta IN ('Activo', 'Bloqueado', 'Suspendido')),
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    bloqueo_hasta TIMESTAMPTZ NULL,
    metodo_autenticacion VARCHAR(50) NOT NULL DEFAULT 'Email/Password',
    ultima_ip_conexion VARCHAR(45) NULL,
    autenticacion_2fa_activado BOOLEAN NOT NULL DEFAULT FALSE,
    -- Campos específicos para conductores
    numero_licencia VARCHAR(30) NULL UNIQUE,
    categoria_licencia VARCHAR(10) NULL,
    fecha_emision_licencia DATE NULL,
    fecha_vencimiento_licencia DATE NULL,
    licencia_validada BOOLEAN NOT NULL DEFAULT FALSE,
    saldo_comisiones_acumuladas DECIMAL(18,2) NOT NULL DEFAULT 0,
    fecha_ultimo_pago_comision DATE NULL,
    horas_conducidas_hoy DECIMAL(5,2) NOT NULL DEFAULT 0,
    limite_horas_continuas INTEGER NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 5. TABLAS DE SEGURIDAD Y AUTENTICACIÓN
-- =======================================================================

-- 5.1 Recuperación de Contraseña
CREATE TABLE public.recuperacion_contrasena (
    id_recuperacion SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    token_recuperacion VARCHAR(255) NOT NULL UNIQUE,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.2 Tokens de Sesión
CREATE TABLE public.tokens_sesion (
    id_token SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    token TEXT NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    dispositivo VARCHAR(255) NULL,
    ip_origen VARCHAR(45) NULL,
    revocado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.3 Logs de Actividad
CREATE TABLE public.logs_actividad (
    id_log SERIAL PRIMARY KEY,
    id_usuario UUID NULL REFERENCES public.usuarios(id_usuario),
    accion VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_origen VARCHAR(45) NULL,
    detalles JSONB NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.4 Intentos de Acceso
CREATE TABLE public.intentos_acceso (
    id_intento SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    ip_origen VARCHAR(45) NOT NULL,
    fecha_intento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    exito BOOLEAN NOT NULL DEFAULT FALSE,
    user_agent VARCHAR(255) NULL,
    motivo_fallo VARCHAR(100) NULL,
    pais_origen VARCHAR(50) NULL,
    ciudad_origen VARCHAR(50) NULL,
    latitud DECIMAL(10,8) NULL,
    longitud DECIMAL(11,8) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.5 Auditoría de Cambios
CREATE TABLE public.auditoria_cambios (
    id_auditoria SERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(50) NOT NULL,
    id_registro VARCHAR(36) NOT NULL,
    accion VARCHAR(10) NOT NULL CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE')),
    usuario_id UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    ip_origen VARCHAR(45) NULL,
    fecha_cambio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    datos_anteriores JSONB NULL,
    datos_nuevos JSONB NULL,
    campos_modificados JSONB NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.6 Permisos Detallados
CREATE TABLE public.permisos_detallados (
    id_permiso SERIAL PRIMARY KEY,
    nombre_permiso VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL,
    modulo VARCHAR(30) NOT NULL,
    accion VARCHAR(30) NOT NULL,
    categoria VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.7 Rol-Permisos
CREATE TABLE public.rol_permisos (
    id_rol INTEGER NOT NULL REFERENCES public.roles_permisos(id_rol),
    id_permiso INTEGER NOT NULL REFERENCES public.permisos_detallados(id_permiso),
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    asignado_por UUID NULL REFERENCES public.usuarios(id_usuario),
    PRIMARY KEY (id_rol, id_permiso),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.8 Sesiones Activas
CREATE TABLE public.sesiones_activas (
    id_sesion SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    token_jti VARCHAR(50) NOT NULL UNIQUE,
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    fecha_ultima_actividad TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_origen VARCHAR(45) NOT NULL,
    dispositivo VARCHAR(255) NOT NULL,
    navegador VARCHAR(50) NULL,
    sistema_operativo VARCHAR(50) NULL,
    es_movil BOOLEAN NOT NULL DEFAULT FALSE,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 6. TABLAS DE VEHÍCULOS Y CONDUCTORES
-- =======================================================================

-- 6.1 Vehículos
CREATE TABLE public.vehiculos (
    id_vehiculo SERIAL PRIMARY KEY,
    id_tipo INTEGER NULL REFERENCES public.tipos_vehiculo(id_tipo),
    matricula VARCHAR(20) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    capacidad_maxima INTEGER NOT NULL CHECK (capacidad_maxima > 0),
    tipo_combustible VARCHAR(30) NOT NULL,
    distribucion_asientos JSONB NULL,
    cantidad_pisos INTEGER NOT NULL DEFAULT 1,
    fecha_vencimiento_matricula DATE NOT NULL,
    fecha_vencimiento_soat DATE NOT NULL,
    fecha_vencimiento_tecnomecanica DATE NOT NULL,
    documentos_vehiculo_validados BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.2 Conductores
CREATE TABLE public.conductores (
    id_conductor SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL UNIQUE REFERENCES public.usuarios(id_usuario),
    numero_identidad_conductor VARCHAR(20) NOT NULL UNIQUE,
    fecha_nacimiento_conductor DATE NOT NULL,
    numero_licencia VARCHAR(30) NOT NULL UNIQUE,
    categoria_licencia VARCHAR(10) NOT NULL,
    fecha_emision_licencia DATE NOT NULL,
    fecha_vencimiento_licencia DATE NOT NULL,
    licencia_validada BOOLEAN NOT NULL DEFAULT FALSE,
    saldo_comisiones_acumuladas DECIMAL(18,2) NOT NULL DEFAULT 0,
    fecha_ultimo_pago_comision DATE NULL,
    horas_conducidas_hoy DECIMAL(5,2) NOT NULL DEFAULT 0,
    limite_horas_continuas INTEGER NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.3 Asignaciones de Vehículos a Conductores
CREATE TABLE public.asignaciones_vehiculo_conductor (
    id_asignacion SERIAL PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    id_conductor INTEGER NOT NULL REFERENCES public.conductores(id_conductor),
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_desasignacion TIMESTAMPTZ NULL,
    motivo_desasignacion VARCHAR(255) NULL,
    estado_asignacion VARCHAR(20) NOT NULL DEFAULT 'ACTIVA' CHECK (estado_asignacion IN ('ACTIVA', 'INACTIVA', 'TEMPORAL')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.4 Mantenimiento de Vehículos
CREATE TABLE public.mantenimiento_vehiculos (
    id_mantenimiento SERIAL PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    tipo_mantenimiento VARCHAR(30) NOT NULL CHECK (tipo_mantenimiento IN ('PREVENTIVO', 'CORRECTIVO', 'PREDICTIVO', 'EMERGENCIA')),
    fecha_programada DATE NOT NULL,
    fecha_realizada DATE NULL,
    kilometraje_actual INTEGER NOT NULL,
    costo DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    descripcion TEXT NULL,
    taller_nombre VARCHAR(100) NOT NULL,
    taller_telefono VARCHAR(20) NULL,
    taller_direccion VARCHAR(200) NULL,
    factura_url VARCHAR(255) NULL,
    estado_mantenimiento VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADO' CHECK (estado_mantenimiento IN ('PROGRAMADO', 'EN_CURSO', 'COMPLETADO', 'CANCELADO')),
    proximo_mantenimiento_km INTEGER NULL,
    observaciones TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.5 Historial de Kilometraje
CREATE TABLE public.historial_km_vehiculo (
    id_historial_km SERIAL PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    kilometraje INTEGER NOT NULL,
    tipo_registro VARCHAR(20) NOT NULL CHECK (tipo_registro IN ('INICIO_ITINERARIO', 'FIN_ITINERARIO', 'MANTENIMIENTO', 'REVISION', 'OTRO')),
    id_itinerario INTEGER NULL,
    id_mantenimiento INTEGER NULL REFERENCES public.mantenimiento_vehiculos(id_mantenimiento),
    observaciones VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 7. TABLAS DE RUTAS Y OPERACIONES
-- =======================================================================

-- 7.1 Rutas
CREATE TABLE public.rutas (
    id_ruta SERIAL PRIMARY KEY,
    id_ciudad_origen INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    id_ciudad_destino INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    distancia_km DECIMAL(10,2) NOT NULL,
    duracion_estimada TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.2 Itinerarios
CREATE TABLE public.itinerarios (
    id_itinerario SERIAL PRIMARY KEY,
    id_ruta INTEGER NOT NULL REFERENCES public.rutas(id_ruta),
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    id_conductor INTEGER NOT NULL REFERENCES public.conductores(id_conductor),
    fecha_salida TIMESTAMPTZ NOT NULL,
    hora_salida TIME NOT NULL,
    fecha_llegada_estimada TIMESTAMPTZ NULL,
    estado_itinerario VARCHAR(20) NOT NULL DEFAULT 'Programado' CHECK (estado_itinerario IN ('Programado', 'En Curso', 'Completado', 'Cancelado')),
    capacidad_disponible INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.3 Detalle de Asientos por Itinerario
CREATE TABLE public.detalle_asientos_itinerario (
    id_detalle SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    codigo_asiento VARCHAR(5) NOT NULL,
    estado_ocupacion VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE' CHECK (estado_ocupacion IN ('DISPONIBLE', 'RESERVADO', 'OCUPADO', 'MANTENIMIENTO')),
    id_pasajero UUID NULL REFERENCES public.usuarios(id_usuario),
    fecha_reserva TIMESTAMPTZ NULL,
    id_categoria_asiento INTEGER NULL REFERENCES public.categorias_asiento(id_categoria),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (id_itinerario, codigo_asiento)
);

-- 7.4 Reservas
CREATE TABLE public.reservas (
    id_reserva SERIAL PRIMARY KEY,
    id_pasajero UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_asiento INTEGER NOT NULL REFERENCES public.detalle_asientos_itinerario(id_detalle),
    fecha_reserva TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado_reserva VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_reserva IN ('PENDIENTE', 'CONFIRMADA', 'CANCELADA', 'EXPIRADA')),
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    monto_pagado DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    codigo_confirmacion VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.5 Paradas Intermedias
CREATE TABLE public.paradas_intermedias (
    id_parada SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_ciudad INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    orden_parada INTEGER NOT NULL,
    hora_llegada_estimada TIMESTAMPTZ NULL,
    hora_salida_estimada TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.6 Costos Operativos
CREATE TABLE public.costos_operativos_itinerario (
    id_costo SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    tipo_costo VARCHAR(30) NOT NULL CHECK (tipo_costo IN ('PEAJE', 'COMBUSTIBLE', 'LAVADO', 'MANTENIMIENTO_RUTA')),
    monto DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    evidencia_comprobante_url VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.7 Registro de Descansos
CREATE TABLE public.registro_descansos (
    id_descanso SERIAL PRIMARY KEY,
    id_conductor INTEGER NOT NULL REFERENCES public.conductores(id_conductor),
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    fecha_inicio_descanso TIMESTAMPTZ NOT NULL,
    fecha_fin_descanso TIMESTAMPTZ NULL,
    duracion_minutos INTEGER NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 8. MÓDULO FINANCIERO
-- =======================================================================

-- 8.1 Precios en Múltiples Monedas
CREATE TABLE public.precios_multimoneda (
    id_precio SERIAL PRIMARY KEY,
    id_ruta INTEGER NOT NULL REFERENCES public.rutas(id_ruta),
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    precio_base DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (id_ruta, id_moneda)
);

-- 8.2 Tipos de Cambio
CREATE TABLE public.tipos_cambio (
    id_tipo_cambio SERIAL PRIMARY KEY,
    id_moneda_origen INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    id_moneda_destino INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    tasa DECIMAL(18,6) NOT NULL,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.3 Instrumentos de Pago
CREATE TABLE public.instrumentos_pago (
    id_instrumento SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    tipo_pago VARCHAR(30) NOT NULL CHECK (tipo_pago IN ('TARJETA_CREDITO', 'TARJETA_DEBITO', 'CUENTA_BANCO', 'BILLETERA_DIGITAL')),
    marca VARCHAR(30) NOT NULL,
    ultimos_digitos VARCHAR(4) NOT NULL,
    nombre_titular VARCHAR(100) NOT NULL,
    token_proveedor VARCHAR(255) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    es_predeterminado BOOLEAN NOT NULL DEFAULT FALSE,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'EXPIRADO', 'ELIMINADO_POR_USUARIO', 'RECHAZADO_POR_BANCO')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.4 Facturas
CREATE TABLE public.facturas (
    id_factura SERIAL PRIMARY KEY,
    id_reserva INTEGER NOT NULL REFERENCES public.reservas(id_reserva),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    numero_factura VARCHAR(50) NOT NULL UNIQUE,
    fecha_emision TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    subtotal DECIMAL(18,2) NOT NULL,
    impuestos DECIMAL(18,2) NOT NULL,
    descuentos DECIMAL(18,2) NOT NULL DEFAULT 0,
    total DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    tipo_documento VARCHAR(20) NOT NULL DEFAULT 'FACTURA' CHECK (tipo_documento IN ('FACTURA', 'BOLETA', 'NOTA_CREDITO', 'NOTA_DEBITO')),
    estado_factura VARCHAR(20) NOT NULL DEFAULT 'EMITIDA' CHECK (estado_factura IN ('EMITIDA', 'PAGADA', 'ANULADA', 'CREDITO_NOTA', 'VENCIDA')),
    url_pdf VARCHAR(255) NULL,
    url_xml VARCHAR(255) NULL,
    fecha_pago TIMESTAMPTZ NULL,
    metodo_pago VARCHAR(30) NULL,
    referencia_pago VARCHAR(100) NULL,
    observaciones TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.5 Pagos
CREATE TABLE public.pagos (
    id_pago SERIAL PRIMARY KEY,
    id_reserva INTEGER NOT NULL REFERENCES public.reservas(id_reserva),
    id_instrumento_pago INTEGER NOT NULL REFERENCES public.instrumentos_pago(id_instrumento),
    monto DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    referencia_transaccion VARCHAR(100) NOT NULL UNIQUE,
    estado_pago VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_pago IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'CANCELADO', 'REVERSADO', 'CAPTURADO')),
    codigo_autorizacion VARCHAR(50) NULL,
    mensaje_respuesta VARCHAR(255) NULL,
    gateway_utilizado VARCHAR(50) NOT NULL,
    fecha_confirmacion TIMESTAMPTZ NULL,
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    metadata_adicional JSONB NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.6 Conciliación Bancaria
CREATE TABLE public.conciliacion_bancaria (
    id_conciliacion SERIAL PRIMARY KEY,
    id_pago INTEGER NOT NULL REFERENCES public.pagos(id_pago),
    fecha_conciliacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado_conciliacion VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_conciliacion IN ('PENDIENTE', 'CONCILIADO', 'DIFERENCIA', 'RECHAZADO')),
    monto_conciliado DECIMAL(18,2) NOT NULL,
    fecha_banco TIMESTAMPTZ NOT NULL,
    referencia_banco VARCHAR(100) NOT NULL,
    observaciones VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.7 Retenciones e Impuestos
CREATE TABLE public.retenciones_impuestos (
    id_retencion SERIAL PRIMARY KEY,
    id_factura INTEGER NOT NULL REFERENCES public.facturas(id_factura),
    tipo_impuesto VARCHAR(30) NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,
    monto DECIMAL(18,2) NOT NULL,
    base_calculo DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.8 Políticas de Cancelación
CREATE TABLE public.politicas_cancelacion (
    id_politica SERIAL PRIMARY KEY,
    id_ruta INTEGER NULL REFERENCES public.rutas(id_ruta),
    horas_antes_viaje INTEGER NOT NULL,
    porcentaje_reembolso DECIMAL(5,2) NOT NULL,
    penalizacion_fija DECIMAL(18,2) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.9 Solicitudes de Cancelación
CREATE TABLE public.solicitudes_cancelacion (
    id_solicitud SERIAL PRIMARY KEY,
    id_reserva INTEGER NOT NULL REFERENCES public.reservas(id_reserva),
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    motivo_cancelacion TEXT NULL,
    monto_reembolsado DECIMAL(18,2) NOT NULL,
    metodo_reembolso VARCHAR(30) NOT NULL CHECK (metodo_reembolso IN ('SALDO_APP', 'MISMO_METODO_PAGO', 'TRANSFERENCIA')),
    estado_proceso VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_proceso IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'PROCESADO')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 9. TABLAS DE HISTORIAL Y TRANSACCIONES
-- =======================================================================

-- 9.1 Historial de Viajes
CREATE TABLE public.historial_viajes (
    id_historial SERIAL PRIMARY KEY,
    id_reserva INTEGER NOT NULL UNIQUE REFERENCES public.reservas(id_reserva),
    id_pasajero UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    fecha_viaje TIMESTAMPTZ NOT NULL,
    tarifa_final DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    estado_viaje VARCHAR(20) NOT NULL DEFAULT 'RESERVADO' CHECK (estado_viaje IN ('RESERVADO', 'EN_CURSO', 'COMPLETADO', 'CANCELADO')),
    calificacion_pasajero INTEGER NULL CHECK (calificacion_pasajero BETWEEN 1 AND 5),
    calificacion_conductor INTEGER NULL CHECK (calificacion_conductor BETWEEN 1 AND 5),
    comentarios TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.2 Historial de Transacciones
CREATE TABLE public.historial_transacciones (
    id_transaccion SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    tipo_transaccion VARCHAR(30) NOT NULL CHECK (tipo_transaccion IN ('PAGO_VIAJE', 'RECARGA_SALDO', 'CANJE_PUNTOS', 'REEMBOLSO', 'COMISION_CONDUCTOR')),
    monto DECIMAL(18,2) NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    descripcion VARCHAR(255) NULL,
    referencia_externa VARCHAR(100) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 10. MÓDULO DE FIDELIZACIÓN
-- =======================================================================

-- 10.1 Billetera de Puntos
CREATE TABLE public.billetera_puntos (
    id_billetera SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL UNIQUE REFERENCES public.usuarios(id_usuario),
    saldo_puntos INTEGER NOT NULL DEFAULT 0,
    puntos_acumulados_vida INTEGER NOT NULL DEFAULT 0,
    puntos_canjeados INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10.2 Reglas de Puntos
CREATE TABLE public.reglas_puntos (
    id_regla SERIAL PRIMARY KEY,
    nombre_regla VARCHAR(100) NOT NULL,
    puntos_otorgados INTEGER NOT NULL,
    condiciones JSONB NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10.3 Canjes de Puntos
CREATE TABLE public.canjes_puntos (
    id_canje SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    puntos_usados INTEGER NOT NULL,
    beneficio_canjeado VARCHAR(255) NOT NULL,
    fecha_canje TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10.4 Programa de Referidos
CREATE TABLE public.programa_referidos (
    id_referido SERIAL PRIMARY KEY,
    id_usuario_referente UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_usuario_referido UUID NOT NULL UNIQUE REFERENCES public.usuarios(id_usuario),
    fecha_referido TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado_referido VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_referido IN ('PENDIENTE', 'ACTIVO', 'COMPLETADO')),
    recompensa_otorgada BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 11. MÓDULO DE EXPERIENCIA DE USUARIO
-- =======================================================================

-- 11.1 Preferencias del Pasajero
CREATE TABLE public.preferencias_pasajero (
    id_preferencia SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL UNIQUE REFERENCES public.usuarios(id_usuario),
    preferencia_asiento VARCHAR(20) NULL CHECK (preferencia_asiento IN ('VENTANA', 'PASILLO', 'NINGUNA')),
    preferencia_clima VARCHAR(30) NULL CHECK (preferencia_clima IN ('AIRE_ACONDICIONADO', 'CALEFACCION', 'INDIFERENTE')),
    requiere_asistencia_especial BOOLEAN NOT NULL DEFAULT FALSE,
    notificaciones_push_activas BOOLEAN NOT NULL DEFAULT TRUE,
    idioma_preferido VARCHAR(10) NOT NULL DEFAULT 'es',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11.2 Viajes Recurrentes
CREATE TABLE public.viajes_recurrentes (
    id_recurrente SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_ruta INTEGER NOT NULL REFERENCES public.rutas(id_ruta),
    dia_semana VARCHAR(10) NOT NULL CHECK (dia_semana IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')),
    hora_preferida_salida TIME NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11.3 Favoritos
CREATE TABLE public.favoritos (
    id_favorito SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_conductor INTEGER NULL REFERENCES public.conductores(id_conductor),
    id_ruta INTEGER NULL REFERENCES public.rutas(id_ruta),
    fecha_agregado TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK ((id_conductor IS NOT NULL AND id_ruta IS NULL) OR (id_conductor IS NULL AND id_ruta IS NOT NULL))
);

-- =======================================================================
-- 12. MÓDULO DE PUBLICIDAD
-- =======================================================================

-- 12.1 Anunciantes
CREATE TABLE public.anunciantes (
    id_anunciante SERIAL PRIMARY KEY,
    nombre_empresa VARCHAR(100) NOT NULL,
    email_contacto VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12.2 Campañas
CREATE TABLE public.campanas (
    id_campana SERIAL PRIMARY KEY,
    id_anunciante INTEGER NOT NULL REFERENCES public.anunciantes(id_anunciante),
    nombre_campana VARCHAR(100) NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    presupuesto_total DECIMAL(18,2) NOT NULL,
    segmentacion JSONB NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12.3 Banners
CREATE TABLE public.banners (
    id_banner SERIAL PRIMARY KEY,
    id_campana INTEGER NOT NULL REFERENCES public.campanas(id_campana),
    url_imagen VARCHAR(255) NOT NULL,
    url_destino VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'IMAGEN' CHECK (tipo IN ('IMAGEN', 'VIDEO', 'TEXTO')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12.4 Métricas de Publicidad
CREATE TABLE public.metricas_publicidad (
    id_metrica SERIAL PRIMARY KEY,
    id_banner INTEGER NOT NULL REFERENCES public.banners(id_banner),
    id_usuario UUID NULL REFERENCES public.usuarios(id_usuario),
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tipo_evento VARCHAR(20) NOT NULL CHECK (tipo_evento IN ('IMPRESION', 'CLICK')),
    ip_origen VARCHAR(45) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 13. MÓDULO DE SOPORTE
-- =======================================================================

-- 13.1 SLA Configuración
CREATE TABLE public.sla_configuracion (
    id_sla SERIAL PRIMARY KEY,
    nombre_sla VARCHAR(50) NOT NULL,
    prioridad VARCHAR(20) NOT NULL CHECK (prioridad IN ('BAJA', 'MEDIA', 'ALTA', 'CRITICA')),
    tiempo_respuesta_horas INTEGER NOT NULL,
    tiempo_resolucion_horas INTEGER NOT NULL,
    penalizacion_incumplimiento VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13.2 Tickets de Soporte
CREATE TABLE public.tickets_soporte (
    id_ticket SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_asignado_a UUID NULL REFERENCES public.usuarios(id_usuario),
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    prioridad VARCHAR(20) NOT NULL DEFAULT 'MEDIA' CHECK (prioridad IN ('BAJA', 'MEDIA', 'ALTA', 'CRITICA')),
    categoria VARCHAR(30) NOT NULL,
    subcategoria VARCHAR(30) NULL,
    estado_ticket VARCHAR(20) NOT NULL DEFAULT 'ABIERTO' CHECK (estado_ticket IN ('ABIERTO', 'EN_PROCESO', 'RESUELTO', 'CERRADO', 'ESCALADO')),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_cierre TIMESTAMPTZ NULL,
    calificacion INTEGER NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentarios_cierre TEXT NULL,
    tiempo_resolucion_minutos INTEGER NULL,
    escalado_nivel INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13.3 Respuestas de Tickets
CREATE TABLE public.respuestas_ticket (
    id_respuesta SERIAL PRIMARY KEY,
    id_ticket INTEGER NOT NULL REFERENCES public.tickets_soporte(id_ticket),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    mensaje TEXT NOT NULL,
    es_interno BOOLEAN NOT NULL DEFAULT FALSE,
    archivo_adjunto_url VARCHAR(255) NULL,
    fecha_respuesta TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13.4 Historial de Tickets
CREATE TABLE public.historial_tickets (
    id_historial SERIAL PRIMARY KEY,
    id_ticket INTEGER NOT NULL REFERENCES public.tickets_soporte(id_ticket),
    fecha_cambio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior TEXT NULL,
    valor_nuevo TEXT NOT NULL,
    usuario_modifico UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 14. MÓDULO DE CHAT Y COMUNICACIÓN
-- =======================================================================

-- 14.1 Mensajes de Chat
CREATE TABLE public.mensajes_chat (
    id_mensaje SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_emisor UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_receptor UUID NULL REFERENCES public.usuarios(id_usuario),
    contenido TEXT NOT NULL,
    tipo_mensaje VARCHAR(20) NOT NULL DEFAULT 'TEXTO' CHECK (tipo_mensaje IN ('TEXTO', 'UBICACION', 'IMAGEN')),
    fecha_envio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    leido BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14.2 Alertas Automáticas
CREATE TABLE public.alertas_automaticas (
    id_alerta SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    tipo_alerta VARCHAR(30) NOT NULL CHECK (tipo_alerta IN ('RETRASO_SALIDA', 'LLEGADA_PROXIMA', 'DESVIO_RUTA', 'CONDUCTOR_ASIGNADO')),
    mensaje VARCHAR(255) NOT NULL,
    fecha_envio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    enviada_por VARCHAR(20) NOT NULL DEFAULT 'SISTEMA' CHECK (enviada_por IN ('SISTEMA', 'ADMIN', 'CONDUCTOR')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 15. MÓDULO DE LOGÍSTICA Y PAQUETERÍA
-- =======================================================================

-- 15.1 Envíos
CREATE TABLE public.envios (
    id_envio SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_remitente UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_destinatario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    codigo_seguimiento VARCHAR(50) NOT NULL UNIQUE,
    tipo_embalaje VARCHAR(20) NOT NULL CHECK (tipo_embalaje IN ('CAJA', 'SOBRE', 'PALET', 'BULTO')),
    contenido_declarado VARCHAR(100) NULL,
    peso DECIMAL(10,2) NOT NULL,
    dimensiones VARCHAR(50) NULL,
    requiere_firma BOOLEAN NOT NULL DEFAULT FALSE,
    valor_asegurado DECIMAL(18,2) NULL,
    estado_trazabilidad VARCHAR(20) NOT NULL DEFAULT 'RECIBIDO' CHECK (estado_trazabilidad IN ('RECIBIDO', 'EN_TRANSITO', 'ENTREGADO', 'DEVUELTO')),
    fecha_entrega_real TIMESTAMPTZ NULL,
    evidencia_foto_url VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15.2 Logística Inversa
CREATE TABLE public.logistica_inversa (
    id_devolucion SERIAL PRIMARY KEY,
    id_envio_original INTEGER NOT NULL REFERENCES public.envios(id_envio),
    motivo_devolucion TEXT NOT NULL,
    estado_devolucion VARCHAR(20) NOT NULL DEFAULT 'SOLICITADA' CHECK (estado_devolucion IN ('SOLICITADA', 'APROBADA', 'EN_TRANSITO', 'DEVUELTA')),
    costo_devolucion DECIMAL(18,2) NULL,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 16. MÓDULO DE INVENTARIO
-- =======================================================================

-- 16.1 Productos en Inventario
CREATE TABLE public.productos_inventario (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT NULL,
    categoria VARCHAR(50) NOT NULL,
    subcategoria VARCHAR(50) NULL,
    peso_unitario DECIMAL(10,2) NOT NULL,
    dimensiones VARCHAR(50) NULL,
    valor_unitario DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    stock_minimo INTEGER NOT NULL DEFAULT 0,
    stock_actual INTEGER NOT NULL DEFAULT 0,
    stock_maximo INTEGER NULL,
    ubicacion_bodega VARCHAR(50) NULL,
    codigo_barras VARCHAR(50) NULL,
    requiere_control_temperatura BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16.2 Movimientos de Inventario
CREATE TABLE public.movimientos_inventario (
    id_movimiento SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES public.productos_inventario(id_producto),
    cantidad INTEGER NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA', 'AJUSTE', 'DEVOLUCION', 'TRANSFERENCIA')),
    id_envio INTEGER NULL REFERENCES public.envios(id_envio),
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario_registro UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    observaciones VARCHAR(255) NULL,
    referencia_documento VARCHAR(50) NULL,
    costo_unitario DECIMAL(18,2) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 17. MÓDULO DE GEOLOCALIZACIÓN Y TRACKING
-- =======================================================================

-- 17.1 Tracking de Vehículos GPS
CREATE TABLE public.tracking_vehiculos (
    id_tracking SERIAL PRIMARY KEY,
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    velocidad_kmh DECIMAL(5,2) NULL,
    direccion_grados INTEGER NULL,
    altitud_metros DECIMAL(8,2) NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    precision_gps DECIMAL(5,2) NULL,
    satelites_visibles INTEGER NULL,
    bateria_porcentaje INTEGER NULL,
    señal_gps_calidad INTEGER NULL CHECK (señal_gps_calidad BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17.2 Zonas Geográficas
CREATE TABLE public.zonas_geograficas (
    id_zona SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_ciudad INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    centro_latitud DECIMAL(10,8) NOT NULL,
    centro_longitud DECIMAL(11,8) NOT NULL,
    radio_metros INTEGER NOT NULL,
    tipo_zona VARCHAR(20) NOT NULL CHECK (tipo_zona IN ('TERMINAL', 'PARADA', 'PUNTO_REFERENCIA', 'RESTRICCION', 'ZONA_SEGURA')),
    color_hex VARCHAR(7) NULL,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17.3 Rutas Recorridas
CREATE TABLE public.rutas_recorridas (
    id_ruta_recorrida SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_vehiculo INTEGER NOT NULL REFERENCES public.vehiculos(id_vehiculo),
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NULL,
    distancia_recorrida_km DECIMAL(10,2) NULL,
    duracion_minutos INTEGER NULL,
    velocidad_promedio DECIMAL(5,2) NULL,
    puntos_tracking INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17.4 Alertas Geográficas
CREATE TABLE public.alertas_geograficas (
    id_alerta_geo SERIAL PRIMARY KEY,
    id_tracking INTEGER NOT NULL REFERENCES public.tracking_vehiculos(id_tracking),
    id_zona INTEGER NOT NULL REFERENCES public.zonas_geograficas(id_zona),
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    tipo_evento VARCHAR(20) NOT NULL CHECK (tipo_evento IN ('ENTRADA', 'SALIDA', 'PERMANENCIA')),
    fecha_evento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    procesada BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 18. MÓDULO TURÍSTICO (PARADAS TURÍSTICAS PARA BUSES)
-- =======================================================================

-- 18.1 Categorías Turísticas
CREATE TABLE public.categorias_turisticas (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    icono VARCHAR(50) NOT NULL,
    color_hex VARCHAR(7) NOT NULL,
    descripcion VARCHAR(200) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    orden_prioridad INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.2 Puntos Turísticos
CREATE TABLE public.puntos_turisticos (
    id_punto SERIAL PRIMARY KEY,
    id_ciudad INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    id_categoria INTEGER NOT NULL REFERENCES public.categorias_turisticas(id_categoria),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    horario_apertura TIME NULL,
    horario_cierre TIME NULL,
    dias_semana_abierto VARCHAR(50) NULL,
    precio_entrada DECIMAL(18,2) NULL,
    id_moneda INTEGER NULL REFERENCES public.monedas(id_moneda),
    tiempo_recomendado_minutos INTEGER NOT NULL DEFAULT 30,
    calificacion_promedio DECIMAL(3,2) NULL CHECK (calificacion_promedio BETWEEN 0 AND 5),
    total_calificaciones INTEGER NOT NULL DEFAULT 0,
    es_gratuito BOOLEAN NOT NULL DEFAULT FALSE,
    requiere_reserva_previa BOOLEAN NOT NULL DEFAULT FALSE,
    telefono_contacto VARCHAR(20) NULL,
    sitio_web VARCHAR(255) NULL,
    url_imagen_principal VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.3 Galería de Puntos Turísticos
CREATE TABLE public.galeria_puntos_turisticos (
    id_imagen SERIAL PRIMARY KEY,
    id_punto INTEGER NOT NULL REFERENCES public.puntos_turisticos(id_punto),
    url_imagen VARCHAR(255) NOT NULL,
    titulo VARCHAR(100) NULL,
    descripcion VARCHAR(200) NULL,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    orden INTEGER NOT NULL DEFAULT 0,
    fecha_subida TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.4 Paradas Turísticas en Itinerarios
CREATE TABLE public.paradas_turisticas_itinerario (
    id_parada_turistica SERIAL PRIMARY KEY,
    id_itinerario INTEGER NOT NULL REFERENCES public.itinerarios(id_itinerario),
    id_punto_turistico INTEGER NOT NULL REFERENCES public.puntos_turisticos(id_punto),
    orden_parada INTEGER NOT NULL,
    hora_llegada_estimada TIMESTAMPTZ NOT NULL,
    hora_salida_estimada TIMESTAMPTZ NOT NULL,
    tiempo_estadia_minutos INTEGER NOT NULL,
    costo_adicional DECIMAL(18,2) NULL,
    id_moneda INTEGER NULL REFERENCES public.monedas(id_moneda),
    incluye_guia BOOLEAN NOT NULL DEFAULT FALSE,
    incluye_entrada BOOLEAN NOT NULL DEFAULT FALSE,
    observaciones TEXT NULL,
    estado_parada VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado_parada IN ('PROGRAMADA', 'EN_CURSO', 'COMPLETADA', 'CANCELADA', 'OMITIDA')),
    fecha_real_llegada TIMESTAMPTZ NULL,
    fecha_real_salida TIMESTAMPTZ NULL,
    comentarios_pasajeros TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.5 Paquetes Turísticos
CREATE TABLE public.paquetes_turisticos (
    id_paquete SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    id_ciudad_origen INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    id_ciudad_destino INTEGER NOT NULL REFERENCES public.ciudades(id_ciudad),
    duracion_estimada_horas DECIMAL(5,2) NOT NULL,
    precio_base DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    incluye_transporte BOOLEAN NOT NULL DEFAULT TRUE,
    incluye_guia BOOLEAN NOT NULL DEFAULT FALSE,
    incluye_almuerzo BOOLEAN NOT NULL DEFAULT FALSE,
    incluye_entradas BOOLEAN NOT NULL DEFAULT FALSE,
    cupo_maximo INTEGER NOT NULL DEFAULT 20,
    cupo_actual INTEGER NOT NULL DEFAULT 0,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    url_imagen_principal VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.6 Detalle de Paquetes Turísticos
CREATE TABLE public.detalle_paquete_turistico (
    id_detalle SERIAL PRIMARY KEY,
    id_paquete INTEGER NOT NULL REFERENCES public.paquetes_turisticos(id_paquete),
    id_punto_turistico INTEGER NOT NULL REFERENCES public.puntos_turisticos(id_punto),
    orden_visita INTEGER NOT NULL,
    tiempo_estimado_minutos INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.7 Reservas de Paquetes Turísticos
CREATE TABLE public.reservas_paquetes_turisticos (
    id_reserva_paquete SERIAL PRIMARY KEY,
    id_paquete INTEGER NOT NULL REFERENCES public.paquetes_turisticos(id_paquete),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    fecha_reserva TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_viaje DATE NOT NULL,
    numero_personas INTEGER NOT NULL,
    precio_total DECIMAL(18,2) NOT NULL,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    estado_reserva VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_reserva IN ('PENDIENTE', 'CONFIRMADA', 'COMPLETADA', 'CANCELADA')),
    codigo_confirmacion VARCHAR(50) NOT NULL UNIQUE,
    necesidades_especiales TEXT NULL,
    contacto_emergencia VARCHAR(100) NULL,
    telefono_emergencia VARCHAR(20) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18.8 Calificaciones de Puntos Turísticos
CREATE TABLE public.calificaciones_puntos_turisticos (
    id_calificacion SERIAL PRIMARY KEY,
    id_punto INTEGER NOT NULL REFERENCES public.puntos_turisticos(id_punto),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_itinerario INTEGER NULL REFERENCES public.itinerarios(id_itinerario),
    puntuacion INTEGER NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario TEXT NULL,
    fecha_calificacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    recomendado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (id_punto, id_usuario)
);

-- 18.9 Historial de Visitas Turísticas
CREATE TABLE public.historial_visitas_turisticas (
    id_visita SERIAL PRIMARY KEY,
    id_parada_turistica INTEGER NOT NULL REFERENCES public.paradas_turisticas_itinerario(id_parada_turistica),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    fecha_visita TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tiempo_permanencia_minutos INTEGER NULL,
    compro_realizadas DECIMAL(18,2) NULL,
    observaciones TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 19. MÓDULO DE MARKETING
-- =======================================================================

-- 19.1 Cupones
CREATE TABLE public.cupones (
    id_cupon SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    tipo_descuento VARCHAR(20) NOT NULL CHECK (tipo_descuento IN ('PORCENTAJE', 'MONTO_FIJO', 'ENVIO_GRATIS')),
    valor_descuento DECIMAL(18,2) NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    uso_maximo INTEGER NOT NULL,
    usos_actuales INTEGER NOT NULL DEFAULT 0,
    uso_por_usuario INTEGER NULL,
    id_ruta INTEGER NULL REFERENCES public.rutas(id_ruta),
    id_usuario_especifico UUID NULL REFERENCES public.usuarios(id_usuario),
    monto_minimo_compra DECIMAL(18,2) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    descripcion VARCHAR(255) NULL,
    categoria_cliente VARCHAR(30) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19.2 Uso de Cupones
CREATE TABLE public.uso_cupones (
    id_uso SERIAL PRIMARY KEY,
    id_cupon INTEGER NOT NULL REFERENCES public.cupones(id_cupon),
    id_reserva INTEGER NOT NULL REFERENCES public.reservas(id_reserva),
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    fecha_uso TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto_descontado DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19.3 Segmentos de Clientes
CREATE TABLE public.segmentos_clientes (
    id_segmento SERIAL PRIMARY KEY,
    nombre_segmento VARCHAR(50) NOT NULL UNIQUE,
    criterios_segmentacion JSONB NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19.4 Usuarios Segmentos
CREATE TABLE public.usuarios_segmentos (
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_segmento INTEGER NOT NULL REFERENCES public.segmentos_clientes(id_segmento),
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id_usuario, id_segmento),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 20. MÓDULO DE NOTIFICACIONES
-- =======================================================================

-- 20.1 Plantillas de Notificaciones
CREATE TABLE public.plantillas_notificaciones (
    id_plantilla SERIAL PRIMARY KEY,
    nombre_plantilla VARCHAR(50) NOT NULL UNIQUE,
    tipo_notificacion VARCHAR(30) NOT NULL,
    asunto VARCHAR(200) NOT NULL,
    contenido_html TEXT NOT NULL,
    contenido_texto TEXT NULL,
    canal_predeterminado VARCHAR(30) NOT NULL,
    variables_disponibles JSONB NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20.2 Notificaciones
CREATE TABLE public.notificaciones (
    id_notificacion SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_plantilla INTEGER NULL REFERENCES public.plantillas_notificaciones(id_plantilla),
    tipo_notificacion VARCHAR(30) NOT NULL CHECK (tipo_notificacion IN ('RESERVA_CONFIRMADA', 'VIAJE_PROXIMO', 'PROMOCION', 'ALERTA', 'RECORDATORIO', 'SISTEMA', 'TICKET', 'FACTURA')),
    titulo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    mensaje_corto VARCHAR(255) NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_envio TIMESTAMPTZ NULL,
    fecha_leida TIMESTAMPTZ NULL,
    fecha_confirmacion_lectura TIMESTAMPTZ NULL,
    url_accion VARCHAR(255) NULL,
    prioridad VARCHAR(10) NOT NULL DEFAULT 'NORMAL' CHECK (prioridad IN ('BAJA', 'NORMAL', 'ALTA', 'CRITICA')),
    canal_envio VARCHAR(30) NOT NULL,
    estado_envio VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_envio IN ('PENDIENTE', 'ENVIADO', 'FALLIDO', 'LEIDO', 'CANCELADO')),
    metadata_adicional JSONB NULL,
    id_referencia INTEGER NULL,
    tipo_referencia VARCHAR(30) NULL,
    intentos_envio INTEGER NOT NULL DEFAULT 0,
    error_envio VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20.3 Suscripciones de Usuario
CREATE TABLE public.suscripciones_usuario (
    id_suscripcion SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    canal VARCHAR(30) NOT NULL CHECK (canal IN ('EMAIL', 'PUSH', 'SMS', 'WHATSAPP', 'IN_APP')),
    token_suscripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_cancelacion TIMESTAMPTZ NULL,
    dispositivo_info VARCHAR(255) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 21. MÓDULO DE REPORTES
-- =======================================================================

-- 21.1 Reportes Diarios
CREATE TABLE public.reportes_diarios (
    id_reporte SERIAL PRIMARY KEY,
    fecha_reporte DATE NOT NULL,
    total_viajes INTEGER NOT NULL DEFAULT 0,
    total_ingresos DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_pasajeros INTEGER NOT NULL DEFAULT 0,
    promedio_ocupacion DECIMAL(5,2) NOT NULL DEFAULT 0,
    total_cancelaciones INTEGER NOT NULL DEFAULT 0,
    ingresos_publicidad DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_envios INTEGER NOT NULL DEFAULT 0,
    total_conductores_activos INTEGER NOT NULL DEFAULT 0,
    total_vehiculos_activos INTEGER NOT NULL DEFAULT 0,
    id_moneda INTEGER NOT NULL REFERENCES public.monedas(id_moneda),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (fecha_reporte, id_moneda)
);

-- 21.2 KPI en Tiempo Real
CREATE TABLE public.kpi_tiempo_real (
    id_kpi SERIAL PRIMARY KEY,
    nombre_kpi VARCHAR(50) NOT NULL,
    valor DECIMAL(18,2) NOT NULL,
    valor_anterior DECIMAL(18,2) NULL,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_actualizacion_anterior TIMESTAMPTZ NULL,
    categoria VARCHAR(30) NOT NULL CHECK (categoria IN ('OPERACIONES', 'FINANCIERO', 'CLIENTES', 'FLOTA', 'LOGISTICA')),
    tendencia VARCHAR(10) NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21.3 Métricas de Satisfacción
CREATE TABLE public.metricas_satisfaccion (
    id_metrica SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_reserva INTEGER NOT NULL REFERENCES public.reservas(id_reserva),
    tipo_encuesta VARCHAR(30) NOT NULL CHECK (tipo_encuesta IN ('VIAJE', 'ATENCION', 'APP', 'CONDUCTOR', 'GENERAL')),
    puntuacion INTEGER NOT NULL CHECK (puntuacion BETWEEN 1 AND 10),
    comentario TEXT NULL,
    fecha_respuesta TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 22. HISTORIAL DE VALIDACIONES DOCUMENTALES
-- =======================================================================

CREATE TABLE public.historial_validaciones_doc (
    id_historial SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_vehiculo INTEGER NULL REFERENCES public.vehiculos(id_vehiculo),
    tipo_documento VARCHAR(30) NOT NULL CHECK (tipo_documento IN ('CEDULA_PAX', 'CEDULA_CONDUCTOR', 'LICENCIA', 'MATRICULA', 'SOAT', 'REV_TECNICA')),
    estado_validacion VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_validacion IN ('PENDIENTE', 'APROBADO_SISTEMA', 'APROBADO_MANUAL', 'RECHAZADO')),
    motivo_rechazo TEXT NULL,
    documento_evidencia_url VARCHAR(255) NULL,
    validado_por VARCHAR(100) NULL,
    fecha_validacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 23. CONFIGURACIÓN DEL SISTEMA
-- =======================================================================

CREATE TABLE public.configuracion_sistema (
    id_config SERIAL PRIMARY KEY,
    clave VARCHAR(50) NOT NULL UNIQUE,
    valor TEXT NOT NULL,
    descripcion VARCHAR(200) NULL,
    categoria VARCHAR(30) NOT NULL,
    tipo_dato VARCHAR(20) NOT NULL DEFAULT 'STRING' CHECK (tipo_dato IN ('STRING', 'INT', 'DECIMAL', 'BOOLEAN', 'JSON', 'DATE', 'TIME')),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_por UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================================
-- 24. TRIGGERS PARA ACTUALIZAR TIMESTAMPS
-- =======================================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a todas las tablas con updated_at
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN (
            'monedas', 'roles_permisos', 'usuarios', 'conductores', 'vehiculos',
            'rutas', 'itinerarios', 'reservas', 'facturas', 'pagos',
            'cupones', 'notificaciones', 'tickets_soporte', 'campanas',
            'paquetes_turisticos', 'puntos_turisticos', 'categorias_turisticas'
        )
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_updated_at ON public.%I;
            CREATE TRIGGER update_%I_updated_at
            BEFORE UPDATE ON public.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
        ', table_name, table_name, table_name, table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =======================================================================
-- 25. FUNCIONES ÚTILES
-- =======================================================================

-- 25.1 Función para generar código de confirmación
CREATE OR REPLACE FUNCTION generar_codigo_confirmacion()
RETURNS VARCHAR(50) AS $$
DECLARE
    codigo VARCHAR(50);
BEGIN
    codigo := 'TEY-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)) || '-' || 
              TO_CHAR(NOW(), 'YYMMDD');
    RETURN codigo;
END;
$$ LANGUAGE plpgsql;

-- 25.2 Función para calcular distancia entre puntos
CREATE OR REPLACE FUNCTION calcular_distancia(
    lat1 DECIMAL(10,8),
    lon1 DECIMAL(11,8),
    lat2 DECIMAL(10,8),
    lon2 DECIMAL(11,8)
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    distancia DECIMAL(10,2);
BEGIN
    -- Fórmula de Haversine (distancia en kilómetros)
    distancia := 6371 * ACOS(
        COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * 
        COS(RADIANS(lon2) - RADIANS(lon1)) + 
        SIN(RADIANS(lat1)) * SIN(RADIANS(lat2))
    );
    RETURN distancia;
END;
$$ LANGUAGE plpgsql;

-- 25.3 Función para obtener puntos turísticos cercanos
CREATE OR REPLACE FUNCTION puntos_turisticos_cercanos(
    p_latitud DECIMAL(10,8),
    p_longitud DECIMAL(11,8),
    p_radio_km DECIMAL(5,2) DEFAULT 10
)
RETURNS TABLE (
    id_punto INTEGER,
    nombre VARCHAR(100),
    categoria VARCHAR(50),
    distancia_km DECIMAL(10,2),
    calificacion DECIMAL(3,2),
    url_imagen VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.id_punto,
        pt.nombre,
        cat.nombre AS categoria,
        calcular_distancia(p_latitud, p_longitud, pt.latitud, pt.longitud) AS distancia_km,
        pt.calificacion_promedio AS calificacion,
        pt.url_imagen_principal AS url_imagen
    FROM public.puntos_turisticos pt
    INNER JOIN public.categorias_turisticas cat ON pt.id_categoria = cat.id_categoria
    WHERE pt.activo = TRUE
        AND calcular_distancia(p_latitud, p_longitud, pt.latitud, pt.longitud) <= p_radio_km
    ORDER BY distancia_km ASC;
END;
$$ LANGUAGE plpgsql;

-- =======================================================================
-- 26. DATOS DE CATÁLOGO
-- =======================================================================

-- 26.1 Monedas
INSERT INTO public.monedas (codigo, nombre, simbolo) VALUES
('USD', 'Dólar Americano', '$'),
('COP', 'Peso Colombiano', '$'),
('VES', 'Bolívar Soberano', 'Bs.'),
('EUR', 'Euro', '€');

-- 26.2 Roles
INSERT INTO public.roles_permisos (nombre_rol, permisos) VALUES
('SUPER_ADMIN', '{"ver_finanzas":true, "editar_conductores":true, "cancelar_viajes":true, "gestionar_admins":true}'),
('ADMIN_OPERACIONES', '{"ver_finanzas":false, "editar_conductores":true, "cancelar_viajes":true, "gestionar_admins":false}'),
('ADMIN_FINANCIERO', '{"ver_finanzas":true, "editar_conductores":false, "cancelar_viajes":false, "gestionar_admins":false}'),
('AGENTE_SOPORTE', '{"ver_finanzas":false, "editar_conductores":false, "cancelar_viajes":true, "gestionar_admins":false}'),
('MARKETING', '{"ver_finanzas":false, "editar_conductores":false, "cancelar_viajes":false, "gestionar_admins":false}');

-- 26.3 País
INSERT INTO public.paises (nombre, codigo_iso2) VALUES ('Venezuela', 'VE');

-- 26.4 Estados
INSERT INTO public.estados (id_pais, nombre) VALUES
(1, 'Distrito Capital'),
(1, 'Carabobo'),
(1, 'Lara'),
(1, 'Falcón');

-- 26.5 Ciudades
INSERT INTO public.ciudades (id_estado, nombre, codigo_postal) VALUES
(1, 'Caracas', '1010'),
(1, 'El Hatillo', '1083'),
(2, 'Valencia', '2001'),
(2, 'Puerto Cabello', '2050'),
(3, 'Barquisimeto', '3001'),
(4, 'Punto Fijo', '1402');

-- 26.6 Categorías de Asientos
INSERT INTO public.categorias_asiento (nombre, factor_precio, descripcion) VALUES
('ESTANDAR', 1.00, 'Asiento estándar'),
('PREMIUM', 1.30, 'Asiento con más espacio'),
('PRIMERA_CLASE', 1.80, 'Asiento ejecutivo con servicios premium'),
('EJECUTIVO', 1.50, 'Asiento ejecutivo');

-- 26.7 Tipos de Vehículo
INSERT INTO public.tipos_vehiculo (nombre, descripcion, capacidad_pasajeros, capacidad_equipaje_kg) VALUES
('BUS_ESTANDAR', 'Autobús estándar para transporte de pasajeros', 40, 500),
('BUS_PREMIUM', 'Autobús de lujo con servicios premium', 30, 800),
('BUS_DOS_PISOS', 'Autobús de dos pisos', 60, 1000),
('MINIBUS', 'Minibús para rutas cortas', 20, 300);

-- 26.8 Categorías Turísticas
INSERT INTO public.categorias_turisticas (nombre, icono, color_hex, descripcion, orden_prioridad) VALUES
('Monumentos', '#8B4513', 'Monumentos históricos y arquitectónicos', 1),
('Museos',  '#2C3E50', 'Museos de arte, historia y cultura', 2),
('Parques Naturales', '#2ECC71', 'Parques, reservas naturales y zonas verdes', 3),
('Playas', '#3498DB', 'Playas y costas', 4),
('Gastronomía', '#E67E22', 'Restaurantes y experiencias gastronómicas', 5),
('Arte', '#9B59B6', 'Galerías de arte y expresiones culturales', 6),
('Aventura', '#E74C3C', 'Actividades de aventura y deportes extremos', 7),
('Religiosos', '#7F8C8D', 'Templos, iglesias y lugares sagrados', 8),
('Compras', '#F39C12', 'Centros comerciales y mercados', 9),
('Eventos', '#1ABC9C', 'Lugares para eventos y espectáculos', 10);

-- 26.9 Puntos Turísticos
INSERT INTO public.puntos_turisticos (
    id_ciudad, id_categoria, nombre, descripcion, direccion,
    latitud, longitud, horario_apertura, horario_cierre,
    dias_semana_abierto, precio_entrada, id_moneda,
    tiempo_recomendado_minutos, es_gratuito, requiere_reserva_previa
)
VALUES
(
    (SELECT id_ciudad FROM public.ciudades WHERE nombre = 'Caracas'),
    (SELECT id_categoria FROM public.categorias_turisticas WHERE nombre = 'Monumentos'),
    'El Ávila',
    'Parque Nacional Waraira Repano, montaña emblemática de Caracas',
    'Parque Nacional El Ávila, Caracas',
    10.5000, -66.9167,
    '07:00', '18:00',
    'LUN-DOM',
    5.00, (SELECT id_moneda FROM public.monedas WHERE codigo = 'USD'),
    120, FALSE, FALSE
);

INSERT INTO public.puntos_turisticos (
    id_ciudad, id_categoria, nombre, descripcion, direccion,
    latitud, longitud, horario_apertura, horario_cierre,
    dias_semana_abierto, precio_entrada, id_moneda,
    tiempo_recomendado_minutos, es_gratuito, requiere_reserva_previa
)
VALUES
(
    (SELECT id_ciudad FROM public.ciudades WHERE nombre = 'Valencia'),
    (SELECT id_categoria FROM public.categorias_turisticas WHERE nombre = 'Parques Naturales'),
    'Parque Negra Hipólita',
    'Parque ecológico con laguna y áreas verdes',
    'Parque Negra Hipólita, Valencia',
    10.1800, -68.0000,
    '06:00', '18:00',
    'LUN-DOM',
    0.00, (SELECT id_moneda FROM public.monedas WHERE codigo = 'VES'),
    60, TRUE, FALSE
);

-- 26.10 Segmentos de Clientes
INSERT INTO public.segmentos_clientes (nombre_segmento, criterios_segmentacion) VALUES
('NUEVOS', '{"dias_antiguedad": "< 30", "viajes_totales": "< 3"}'),
('FRECUENTES', '{"viajes_totales": ">= 10", "dias_antiguedad": "> 90"}'),
('VIP', '{"viajes_totales": ">= 30", "gasto_total": "> 1000000"}'),
('INACTIVOS', '{"dias_ultimo_viaje": "> 90"}'),
('PROMOTORES', '{"puntuacion_satisfaccion": ">= 8", "referidos": ">= 3"}');

-- 26.11 Configuración Inicial
INSERT INTO public.configuracion_sistema (clave, valor, descripcion, categoria, tipo_dato, actualizado_por) VALUES
('TIEMPO_EXPIRACION_RESERVA_MINUTOS', '15', 'Tiempo máximo para confirmar reserva', 'RESERVAS', 'INT', (SELECT id_usuario FROM public.usuarios LIMIT 1)),
('PORCENTAJE_COMISION_CONDUCTOR', '20.00', 'Comisión estándar para conductores', 'FINANCIERO', 'DECIMAL', (SELECT id_usuario FROM public.usuarios LIMIT 1)),
('PUNTOS_POR_VIAJE', '10', 'Puntos otorgados por viaje completado', 'FIDELIZACION', 'INT', (SELECT id_usuario FROM public.usuarios LIMIT 1));

-- =======================================================================
-- 27. ROW LEVEL SECURITY (RLS) PARA SUPABASE
-- =======================================================================

-- Habilitar RLS en todas las tablas
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Crear políticas básicas (ejemplo para USUARIOS)
CREATE POLICY "Usuarios pueden ver su propio perfil"
    ON public.usuarios
    FOR SELECT
    USING (auth.uid() = id_usuario);

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
    ON public.usuarios
    FOR UPDATE
    USING (auth.uid() = id_usuario);

-- Política para SUPABASE_ADMIN (acceso total)
CREATE POLICY "Admins tienen acceso total"
    ON public.usuarios
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.usuarios
            WHERE id_usuario = auth.uid()
            AND id_rol = 1
        )
    );

-- =======================================================================
-- 28. MENSAJE DE FINALIZACIÓN
-- =======================================================================

DO $$
DECLARE
    total_tables INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tables 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    RAISE NOTICE '=======================================================';
    RAISE NOTICE ' BASE DE DATOS TEYEVO PARA SUPABASE CREADA EXITOSAMENTE';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE ' TOTAL DE TABLAS: %', total_tables;
    RAISE NOTICE ' SCRIPT EJECUTADO CORRECTAMENTE';
    RAISE NOTICE '=======================================================';
END;
$$ LANGUAGE plpgsql;