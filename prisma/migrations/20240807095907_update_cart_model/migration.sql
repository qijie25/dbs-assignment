/*
  Warnings:

  - You are about to alter the column `quantity` on the `cart_item` table. The data in that column could be lost. The data in that column will be cast from `Decimal(65,30)` to `Integer`.

*/
-- AlterTable
ALTER TABLE "cart_item" ALTER COLUMN "quantity" SET DATA TYPE INTEGER;
