-- CreateEnum
CREATE TYPE "Provider" AS ENUM ('CARUSO', 'HIGHMOBILITY');

-- CreateEnum
CREATE TYPE "Status" AS ENUM ('Active', 'Inactive', 'Deleted');

-- CreateEnum
CREATE TYPE "Brand" AS ENUM ('AlfaRomeo', 'Audi', 'BMW', 'Citroen', 'Dacia', 'DS', 'Fiat', 'Ford', 'Hyundai', 'Jaguar', 'Jeep', 'Kia', 'LandRover', 'Lexus', 'Maserati', 'MercedesBenz', 'MINI', 'Mobilize', 'Opel', 'Peugeot', 'Porsche', 'Renault', 'Tesla', 'Toyota', 'Vauxhall', 'Volvo');

-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "password" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ModifiedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UnclearedCar" (
    "id" SERIAL NOT NULL,
    "vin" TEXT NOT NULL,
    "provider" "Provider" NOT NULL,
    "brand" "Brand" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modifiedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UnclearedCar_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Car" (
    "id" SERIAL NOT NULL,
    "vin" TEXT NOT NULL,
    "brand" "Brand" NOT NULL,
    "clearedProvider" "Provider"[],
    "preferedProvider" "Provider" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modifiedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Notes" JSONB,
    "status" "Status",

    CONSTRAINT "Car_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" SERIAL NOT NULL,
    "refreshToken" TEXT NOT NULL,
    "userEmail" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MileageEntries" (
    "id" SERIAL NOT NULL,
    "carVin" TEXT NOT NULL,
    "mileage" INTEGER,
    "isValid" BOOLEAN NOT NULL,
    "provider" "Provider" NOT NULL,
    "status" "Status" NOT NULL,
    "deletedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MileageEntries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Error" (
    "id" SERIAL NOT NULL,
    "errorCode" INTEGER NOT NULL,
    "message" TEXT NOT NULL,
    "Notes" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Error_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Car_vin_key" ON "Car"("vin");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_refreshToken_key" ON "RefreshToken"("refreshToken");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userEmail_fkey" FOREIGN KEY ("userEmail") REFERENCES "User"("email") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MileageEntries" ADD CONSTRAINT "MileageEntries_carVin_fkey" FOREIGN KEY ("carVin") REFERENCES "Car"("vin") ON DELETE RESTRICT ON UPDATE CASCADE;
