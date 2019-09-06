ALTER TABLE `receipt` ADD COLUMN `PaymentCash` DECIMAL(10,2) NULL DEFAULT '0.00' AFTER `PaymentAmount`;
ALTER TABLE `receipt` ADD COLUMN `PaymentNets` DECIMAL(10,2) NULL DEFAULT '0.00' AFTER `PaymentCash`;
UPDATE receipt SET PaymentCash=PaymentAmount;

