-- ==========================================
-- MDF & PVC Kaplamalar Yönetim Sistemi
-- Supabase SQL Migrations
-- ==========================================

-- 1. USERS TABLE (Tilek, Mirza, Super Admin)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'manager', -- super_admin / manager / customer
  password_hash TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. CUSTOMERS TABLE (Müşteriler)
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  total_debt DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. MATERIALS_PRICE TABLE (Malzeme Fiyatları)
CREATE TABLE materials_price (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material TEXT NOT NULL, -- boya / mdf / zimpara / tiner / pvc / tutkal
  unit TEXT NOT NULL, -- litre / kg / m2 vb
  unit_price DECIMAL(10, 2) NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. ORDERS TABLE (Siparişler)
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_phone TEXT NOT NULL,
  order_type TEXT NOT NULL, -- mdf_boya / pvc_kaplama
  admin_accepted TEXT, -- Tilek / Mirza (kim kabul etti)
  order_date TIMESTAMP DEFAULT NOW(),
  status TEXT DEFAULT 'pending', -- pending / processing / completed
  total_price DECIMAL(10, 2) DEFAULT 0,
  paid_amount DECIMAL(10, 2) DEFAULT 0,
  remaining_balance DECIMAL(10, 2) DEFAULT 0,
  payment_method TEXT, -- cash / card / kaporta_50 / kapali
  
  -- MDF Boya fields
  mdf_sqm DECIMAL(8, 2),
  mdf_thickness INT,
  paint_color TEXT,
  
  -- PVC Kaplama fields
  pvc_sqm DECIMAL(8, 2),
  mdf_thickness_pvc INT,
  pvc_quantity INT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. PAYMENTS TABLE (Ödemeler)
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  payment_type TEXT NOT NULL, -- first_deposit_50 / final_50 / full / cash
  amount DECIMAL(10, 2) NOT NULL,
  payment_date TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 6. EXPENSES TABLE (Giderler)
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id UUID NOT NULL REFERENCES users(id),
  manager_name TEXT, -- Tilek / Mirza (cache için)
  expense_type TEXT NOT NULL, -- boya / mdf / zimpara / tiner / pvc / tutkal / maas / diger
  amount DECIMAL(10, 2) NOT NULL,
  quantity DECIMAL(10, 2),
  unit_price DECIMAL(10, 2),
  expense_date DATE DEFAULT NOW(),
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================
-- INDEXES (Performans için)
-- ==========================================

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_admin ON orders(admin_accepted);
CREATE INDEX idx_expenses_manager ON expenses(manager_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_payments_order ON payments(order_id);

-- ==========================================
-- DEFAULT DATA (Test için)
-- ==========================================

-- Managers (Tilek & Mirza)
INSERT INTO users (name, email, phone, role) VALUES
  ('Tilek', 'tilek@kaplamalar.kz', '+77001234567', 'manager'),
  ('Mirza', 'mirza@kaplamalar.kz', '+77001234568', 'manager');

-- Material Prices (Bazı varsayılan fiyatlar)
INSERT INTO materials_price (material, unit, unit_price) VALUES
  ('boya', 'litre', 2500),
  ('mdf', 'sheet', 8000),
  ('zimpara', 'kg', 1500),
  ('tiner', 'litre', 800),
  ('pvc', 'metre', 1200),
  ('tutkal', 'kg', 3000);

-- ==========================================
-- RLS POLICIES (Row Level Security)
-- ==========================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials_price ENABLE ROW LEVEL SECURITY;

-- Users: Sadece kendi profili + super admin herkesi görebilir
CREATE POLICY "users_self_view" ON users
  FOR SELECT USING (auth.uid() = id OR (SELECT role FROM users WHERE id = auth.uid()) = 'super_admin');

-- Customers: Herkese görünsün (anonim giriş olacak başlangıçta)
CREATE POLICY "customers_all_read" ON customers
  FOR SELECT USING (true);

-- Orders: Herkese görünsün
CREATE POLICY "orders_all_read" ON orders
  FOR SELECT USING (true);

-- Expenses: Sadece kendi giderleri + super admin
CREATE POLICY "expenses_own_view" ON expenses
  FOR SELECT USING (manager_id = auth.uid() OR (SELECT role FROM users WHERE id = auth.uid()) = 'super_admin');

-- Materials Price: Herkese görünsün
CREATE POLICY "materials_all_read" ON materials_price
  FOR SELECT USING (true);
