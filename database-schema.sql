
CREATE TABLE countries (
    id BIGSERIAL PRIMARY KEY,
    iso_code VARCHAR(2) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    default_timezone VARCHAR(64) NOT NULL
);

CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL,
    email_verified_at TIMESTAMPTZ NULL,
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'en',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (status IN ('pending_verification', 'active', 'suspended', 'closed'))
);

CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    birth_date DATE NOT NULL,
    phone VARCHAR(40),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(30),
    city VARCHAR(120),
    country_id BIGINT REFERENCES countries(id),
    driver_license_number VARCHAR(80),
    driver_license_country VARCHAR(2),
    driver_license_expiry_date DATE
);

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    user_agent TEXT,
    ip_address VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NULL,
    CHECK (expires_at > created_at)
);

CREATE TABLE agencies (
    id UUID PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    country_id BIGINT NOT NULL REFERENCES countries(id),
    city VARCHAR(120) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    postal_code VARCHAR(30) NOT NULL,
    timezone VARCHAR(64) NOT NULL,
    opening_hours_json JSONB,
    phone VARCHAR(40),
    email VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vehicle_categories (
    code VARCHAR(20) PRIMARY KEY,
    acriss_code VARCHAR(4) NOT NULL UNIQUE,
    label VARCHAR(120) NOT NULL,
    transmission VARCHAR(30),
    fuel_type VARCHAR(30),
    seats_min SMALLINT,
    doors_min SMALLINT,
    CHECK (seats_min IS NULL OR seats_min >= 1),
    CHECK (doors_min IS NULL OR doors_min >= 1)
);

CREATE TABLE vehicles (
    id UUID PRIMARY KEY,
    vin VARCHAR(64) NOT NULL UNIQUE,
    registration_number VARCHAR(40) NOT NULL UNIQUE,
    agency_id UUID NOT NULL REFERENCES agencies(id),
    category_code VARCHAR(20) NOT NULL REFERENCES vehicle_categories(code),
    status VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (status IN ('available', 'allocated', 'rented', 'maintenance', 'retired'))
);

CREATE TABLE agency_category_inventory (
    id UUID PRIMARY KEY,
    agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
    category_code VARCHAR(20) NOT NULL REFERENCES vehicle_categories(code),
    total_vehicles INTEGER NOT NULL,
    reservable_vehicles INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (agency_id, category_code),
    CHECK (total_vehicles >= 0),
    CHECK (reservable_vehicles >= 0),
    CHECK (reservable_vehicles <= total_vehicles)
);

CREATE TABLE rental_quotes (
    id UUID PRIMARY KEY,
    user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    pickup_agency_id UUID NOT NULL REFERENCES agencies(id),
    dropoff_agency_id UUID NOT NULL REFERENCES agencies(id),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    category_code VARCHAR(20) NOT NULL REFERENCES vehicle_categories(code),
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    base_amount NUMERIC(12,2) NOT NULL,
    tax_amount NUMERIC(12,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    pricing_snapshot_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (end_at > start_at),
    CHECK (valid_until >= created_at),
    CHECK (status IN ('active', 'expired', 'converted', 'cancelled'))
);

CREATE TABLE reservations (
    id UUID PRIMARY KEY,
    reference VARCHAR(40) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id),
    quote_id UUID NULL REFERENCES rental_quotes(id) ON DELETE SET NULL,
    pickup_agency_id UUID NOT NULL REFERENCES agencies(id),
    dropoff_agency_id UUID NOT NULL REFERENCES agencies(id),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    category_code VARCHAR(20) NOT NULL REFERENCES vehicle_categories(code),
    assigned_vehicle_id UUID NULL REFERENCES vehicles(id) ON DELETE SET NULL,
    status VARCHAR(30) NOT NULL,
    base_amount NUMERIC(12,2) NOT NULL,
    tax_amount NUMERIC(12,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    pricing_snapshot_json JSONB NOT NULL,
    refund_policy_snapshot_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    canceled_at TIMESTAMPTZ NULL,
    cancellation_reason TEXT NULL,
    CHECK (end_at > start_at),
    CHECK (status IN ('pending_payment', 'confirmed', 'modified', 'cancelled', 'completed', 'no_show')),
    CHECK (canceled_at IS NULL OR canceled_at >= created_at)
);

CREATE TABLE inventory_allocations (
    id UUID PRIMARY KEY,
    agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
    category_code VARCHAR(20) NOT NULL REFERENCES vehicle_categories(code),
    reservation_id UUID NULL REFERENCES reservations(id) ON DELETE CASCADE,
    vehicle_id UUID NULL REFERENCES vehicles(id) ON DELETE SET NULL,
    allocation_type VARCHAR(30) NOT NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    released_at TIMESTAMPTZ NULL,
    CHECK (end_at > start_at),
    CHECK (quantity >= 1),
    CHECK (allocation_type IN ('reservation', 'maintenance', 'transfer', 'manual_block')),
    CHECK (status IN ('active', 'released', 'cancelled')),
    CHECK (
        (reservation_id IS NOT NULL AND allocation_type = 'reservation')
        OR (reservation_id IS NULL)
    )
);

CREATE TABLE payments (
    id UUID PRIMARY KEY,
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    provider VARCHAR(40) NOT NULL DEFAULT 'stripe',
    provider_payment_intent_id VARCHAR(255) NOT NULL UNIQUE,
    provider_checkout_session_id VARCHAR(255) UNIQUE,
    amount NUMERIC(12,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    status VARCHAR(30) NOT NULL,
    paid_at TIMESTAMPTZ NULL,
    last_provider_event_at TIMESTAMPTZ NULL,
    provider_payload_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (status IN ('requires_payment_method', 'requires_action', 'processing', 'succeeded', 'cancelled', 'failed', 'partially_refunded', 'refunded'))
);

CREATE TABLE payment_refunds (
    id UUID PRIMARY KEY,
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    provider_refund_id VARCHAR(255) NOT NULL UNIQUE,
    amount NUMERIC(12,2) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    status VARCHAR(30) NOT NULL,
    reason VARCHAR(100),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ NULL,
    CHECK (amount > 0),
    CHECK (status IN ('pending', 'succeeded', 'failed', 'cancelled'))
);

CREATE TABLE support_conversations (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reservation_id UUID NULL REFERENCES reservations(id) ON DELETE SET NULL,
    channel_type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    subject VARCHAR(255),
    external_channel_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at TIMESTAMPTZ NULL,
    closed_at TIMESTAMPTZ NULL,
    CHECK (channel_type IN ('async', 'chat', 'video')),
    CHECK (status IN ('open', 'pending', 'resolved', 'closed'))
);

CREATE TABLE support_messages (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES support_conversations(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL,
    sender_label VARCHAR(120),
    body TEXT NOT NULL,
    attachment_url TEXT,
    external_message_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (sender_type IN ('customer', 'agent', 'system'))
);

CREATE TABLE audit_events (
    id UUID PRIMARY KEY,
    actor_type VARCHAR(30) NOT NULL,
    actor_id UUID,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    action VARCHAR(50) NOT NULL,
    payload_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_agencies_country_city ON agencies(country_id, city);
CREATE INDEX idx_vehicles_agency_category_status ON vehicles(agency_id, category_code, status);
CREATE INDEX idx_inventory_by_agency_category ON agency_category_inventory(agency_id, category_code);
CREATE INDEX idx_quotes_user ON rental_quotes(user_id, created_at DESC);
CREATE INDEX idx_quotes_search ON rental_quotes(pickup_agency_id, dropoff_agency_id, start_at, end_at, category_code);
CREATE INDEX idx_reservations_user_status ON reservations(user_id, status);
CREATE INDEX idx_reservations_dates ON reservations(start_at, end_at);
CREATE INDEX idx_reservations_agencies_dates ON reservations(pickup_agency_id, dropoff_agency_id, start_at, end_at);
CREATE INDEX idx_allocations_search ON inventory_allocations(agency_id, category_code, start_at, end_at, status);
CREATE INDEX idx_allocations_reservation ON inventory_allocations(reservation_id);
CREATE INDEX idx_payments_reservation ON payments(reservation_id);
CREATE INDEX idx_refunds_payment ON payment_refunds(payment_id);
CREATE INDEX idx_support_conversations_user ON support_conversations(user_id);
CREATE INDEX idx_support_messages_conversation ON support_messages(conversation_id, created_at);
CREATE INDEX idx_audit_events_entity ON audit_events(entity_type, entity_id, created_at);
