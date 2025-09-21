-- CreateTable
CREATE TABLE "MarketplaceItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "condition" TEXT NOT NULL,
    "price" REAL NOT NULL,
    "images" JSONB NOT NULL,
    "location" TEXT,
    "sellerId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "views" INTEGER NOT NULL DEFAULT 0,
    "isNegotiable" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "MarketplaceItem_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Auction" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" TEXT NOT NULL,
    "startPrice" REAL NOT NULL,
    "currentBid" REAL,
    "buyNowPrice" REAL,
    "startTime" DATETIME NOT NULL,
    "endTime" DATETIME NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'SCHEDULED',
    "winnerId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Auction_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "MarketplaceItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Auction_winnerId_fkey" FOREIGN KEY ("winnerId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Bid" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" TEXT NOT NULL,
    "auctionId" TEXT,
    "bidderId" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "isWinning" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Bid_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "MarketplaceItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Bid_auctionId_fkey" FOREIGN KEY ("auctionId") REFERENCES "Auction" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Bid_bidderId_fkey" FOREIGN KEY ("bidderId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Offer" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "itemId" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "message" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Offer_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "MarketplaceItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Offer_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserFavorite" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UserFavorite_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "UserFavorite_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "MarketplaceItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "Auction_itemId_key" ON "Auction"("itemId");

-- CreateIndex
CREATE UNIQUE INDEX "UserFavorite_userId_itemId_key" ON "UserFavorite"("userId", "itemId");
