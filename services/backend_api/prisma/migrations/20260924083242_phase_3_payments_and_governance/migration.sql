-- AlterTable
ALTER TABLE "commission_ledgers" ADD COLUMN     "settlement_batch_id" UUID;

-- AlterTable
ALTER TABLE "rider_trip_ledgers" ADD COLUMN     "settlement_batch_id" UUID;

-- AlterTable
ALTER TABLE "riders" ADD COLUMN     "is_approved" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "gateway" VARCHAR(50) NOT NULL,
    "transaction_id" VARCHAR(100),
    "session_key" VARCHAR(150),
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" VARCHAR(10) NOT NULL DEFAULT 'BDT',
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "gateway_response" JSONB,
    "paid_at" TIMESTAMPTZ,
    "failed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlement_batches" (
    "id" UUID NOT NULL,
    "batch_number" VARCHAR(30) NOT NULL,
    "start_date" TIMESTAMPTZ NOT NULL,
    "end_date" TIMESTAMPTZ NOT NULL,
    "total_orders" INTEGER NOT NULL,
    "total_vendor_payout" DECIMAL(12,2) NOT NULL,
    "total_rider_payout" DECIMAL(12,2) NOT NULL,
    "total_platform_margin" DECIMAL(12,2) NOT NULL,
    "status" "SettlementStatus" NOT NULL DEFAULT 'SETTLED',
    "executed_by_user_id" UUID,
    "executed_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "settlement_batches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "payments_transaction_id_key" ON "payments"("transaction_id");

-- CreateIndex
CREATE INDEX "payments_order_id_idx" ON "payments"("order_id");

-- CreateIndex
CREATE INDEX "payments_status_idx" ON "payments"("status");

-- CreateIndex
CREATE UNIQUE INDEX "settlement_batches_batch_number_key" ON "settlement_batches"("batch_number");

-- CreateIndex
CREATE INDEX "commission_ledgers_settlement_batch_id_idx" ON "commission_ledgers"("settlement_batch_id");

-- CreateIndex
CREATE INDEX "rider_trip_ledgers_settlement_batch_id_idx" ON "rider_trip_ledgers"("settlement_batch_id");

-- CreateIndex
CREATE INDEX "riders_is_approved_idx" ON "riders"("is_approved");

-- AddForeignKey
ALTER TABLE "commission_ledgers" ADD CONSTRAINT "commission_ledgers_settlement_batch_id_fkey" FOREIGN KEY ("settlement_batch_id") REFERENCES "settlement_batches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rider_trip_ledgers" ADD CONSTRAINT "rider_trip_ledgers_settlement_batch_id_fkey" FOREIGN KEY ("settlement_batch_id") REFERENCES "settlement_batches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
