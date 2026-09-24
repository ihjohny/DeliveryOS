-- CreateTable
CREATE TABLE "cash_deposits" (
    "id" UUID NOT NULL,
    "rider_id" UUID NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "deposited_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    "reference_no" VARCHAR(50) NOT NULL,
    "note" TEXT,

    CONSTRAINT "cash_deposits_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cash_deposits_reference_no_key" ON "cash_deposits"("reference_no");

-- CreateIndex
CREATE INDEX "cash_deposits_rider_id_idx" ON "cash_deposits"("rider_id");

-- CreateIndex
CREATE INDEX "banners_is_active_idx" ON "banners"("is_active");

-- CreateIndex
CREATE INDEX "categories_vendor_id_idx" ON "categories"("vendor_id");

-- CreateIndex
CREATE INDEX "order_items_product_id_idx" ON "order_items"("product_id");

-- CreateIndex
CREATE INDEX "orders_vendor_id_status_idx" ON "orders"("vendor_id", "status");

-- CreateIndex
CREATE INDEX "orders_placed_at_idx" ON "orders"("placed_at");

-- CreateIndex
CREATE INDEX "riders_is_online_idx" ON "riders"("is_online");

-- CreateIndex
CREATE INDEX "vendor_staff_user_id_idx" ON "vendor_staff"("user_id");

-- AddForeignKey
ALTER TABLE "cash_deposits" ADD CONSTRAINT "cash_deposits_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "riders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Ensure PostGIS is enabled in shadow DB and prod DB
CREATE EXTENSION IF NOT EXISTS postgis;

-- PostGIS GiST Spatial Expression Indexes
CREATE INDEX IF NOT EXISTS "idx_vendors_geo" 
  ON "vendors" USING GIST (CAST(ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326) AS geography));

CREATE INDEX IF NOT EXISTS "idx_customer_addresses_geo" 
  ON "customer_addresses" USING GIST (CAST(ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326) AS geography));

CREATE INDEX IF NOT EXISTS "idx_riders_geo" 
  ON "riders" USING GIST (CAST(ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326) AS geography));
