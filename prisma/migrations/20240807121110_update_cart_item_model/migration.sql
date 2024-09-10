/*
  Warnings:

  - You are about to drop the column `cart_id` on the `cart_item` table. All the data in the column will be lost.
  - You are about to drop the `cart` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `member_id` to the `cart_item` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "cart" DROP CONSTRAINT "fk_cart_member";

-- DropForeignKey
ALTER TABLE "cart_item" DROP CONSTRAINT "fk_cart_item_cart";

-- AlterTable
ALTER TABLE "cart_item" DROP COLUMN "cart_id",
ADD COLUMN     "member_id" INTEGER NOT NULL;

-- DropTable
DROP TABLE "cart";

-- RenameForeignKey
ALTER TABLE "cart_item" RENAME CONSTRAINT "fk_cart_item_product" TO "cart_item_product_id_fkey";

-- AddForeignKey
ALTER TABLE "cart_item" ADD CONSTRAINT "cart_item_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "member"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
