USE DIENMAYSTOREDATABASE

GO

-- CREATE FUNCTION CHECK CONDITION FOR CUSTOMER RANK
CREATE FUNCTION dbo.CheckCustomerRank (@value FLOAT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @result VARCHAR(20)

    SET @result = CASE 
                    WHEN @value >= 0 AND @value <= 5000000 THEN 'Bronze'
                    WHEN @value > 5000000 AND @value <= 20000000 THEN 'Silver'
				    WHEN @value > 20000000 AND @value <= 40000000 THEN 'Gold'
					WHEN @value is null THEN 'Bronze'
					ELSE 'Diamond'
                  END

    RETURN @result
END
GO

-- CREATE TABLE Customer
CREATE TABLE DIENMAYSTOREDATABASE.dbo.Customer(
	CustomerId VARCHAR(20),
	CustomerName NVARCHAR(40) NOT NULL,
	Account NVARCHAR(60) NOT NULL UNIQUE,
	AccoutDescription NVARCHAR(MAX),
	PassWord NVARCHAR(40) NOT NULL,
	Email NVARCHAR(Max),
	BirthDate DATE,
	TotalSpend FLOAT DEFAULT 0,
	TotalSpendRank VARCHAR(20),
	PhoneNumber1 CHAR(20) NOT NULL UNIQUE,
	PhoneNumber2 CHAR(20) UNIQUE,
	--Thiết lập Constraint
	PRIMARY KEY(CustomerId),
	CONSTRAINT CHECK_Customer_TotalSpend_Positive CHECK(TotalSpend >= 0),
	CONSTRAINT CHECK_Customer_PhoneNumber1 CHECK (ISNUMERIC(PhoneNumber1) = 1),
	CONSTRAINT CHECK_Customer_PhoneNumber2 CHECK (ISNUMERIC(PhoneNumber2) = 1 OR PhoneNumber2 IS NULL),
	CONSTRAINT CHECK_Customer_Password CHECK (
	PassWord LIKE '%[0-9]%' AND
    PassWord LIKE '%[a-z]%' AND
    PassWord LIKE '%[^a-zA-Z0-9]%'
),
	CONSTRAINT CHECK_Customer_Email CHECK (Email LIKE '%@gmail.com')
)
GO

-- CREATE TRIGGER TO  UPDATE AUTOMATICALLY  TotalSpendRank ATTRIBUTE
CREATE TRIGGER trg_UpdateTotalSpendRank
ON DIENMAYSTOREDATABASE.dbo.Customer
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE c
    SET TotalSpendRank = dbo.CheckCustomerRank(c.TotalSpend)
    FROM DIENMAYSTOREDATABASE.dbo.Customer AS c
    INNER JOIN inserted AS i ON c.CustomerId = i.CustomerId
END
GO

-- CREATE TABLE CustomerAdress

CREATE TABLE DIENMAYSTOREDATABASE.dbo.CustomerAdress(
	 CustomerAddressId INT PRIMARY KEY IDENTITY(1,1),
	 CustomerId VARCHAR(20),
	 Address NVARCHAR(300),
	 CONSTRAINT FK_CustomerAdress_CustomerId FOREIGN KEY(CustomerId)
	 REFERENCES DIENMAYSTOREDATABASE.dbo.Customer(CustomerId)
);

-- CREATE TABLE WareHouse

CREATE TABLE DIENMAYSTOREDATABASE.dbo.WareHouse(
	 WareHouseId VARCHAR(20),
	 CategoryId VARCHAR(40),
	 WareHouseAddress NVARCHAR(40) NOT NULL,
	 Status NVARCHAR(20) NOT NULL,
	 StartDate DATE
	 PRIMARY KEY(WareHouseId,  CategoryId)
);

-- CREATE TABLE Category

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Category(
	 CategoryId VARCHAR(40),
	 WareHouseId VARCHAR(20),
	 CategoryName NVARCHAR(150),
	 CategoryDescription NVARCHAR(MAX),
	 InputDate DATETIME,
	 [Number Of Product] INT
	 PRIMARY KEY( CategoryId),
	 CONSTRAINT FK_Category_CateWareHouse FOREIGN KEY(WareHouseId, CategoryId) 
	 REFERENCES  DIENMAYSTOREDATABASE.dbo.WareHouse(WareHouseId, CategoryId)
);

GO

-- CREATE FUNCTION CHECK CONDITION FOR Product Status

CREATE FUNCTION dbo.CheckProductStatus (@value INT, @lowlimit INT = 0)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @result VARCHAR(20)

    SET @result = CASE WHEN @value <= @lowlimit THEN 'NO STOCK' ELSE 'STOCK '
                  END

    RETURN @result
END
GO

-- CREATE TABLE Product

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Product(
	 ProductId VARCHAR(40) PRIMARY KEY,
	 ProductName NVARCHAR(MAX) NOT NULL,
	 ProductImage NVARCHAR(MAX),
	 ProviderId NVARCHAR(60) NOT NULL,
	 Price FLOAT NOT NULL,
	 Description NVARCHAR(MAX),
	 CategoryId VARCHAR(40),
	 ProductInputDate VARCHAR(40),
	 StartNumber INT NOT NULL ,
	 PresentNumber INT NOT NULL,
	 Status NVARCHAR(20)
)
GO
-- CREATE TRIGGER TO AUTOMATICALLY UPDATE ProductStatus WHEN  number of present product < lowlimit

CREATE TRIGGER trg_UpdateProductStatus
ON DIENMAYSTOREDATABASE.dbo.Product
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE p
    SET p.Status = dbo.CheckProductStatus(p.PresentNumber,10)
    FROM DIENMAYSTOREDATABASE.dbo.Product AS p
    INNER JOIN inserted AS i ON p.ProductId = i.ProductId
END
GO

-- CREATE TABLE Provider

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Provider(
	ProviderId VARCHAR(60),
	CategoryId VARCHAR(40),
	ProductId VARCHAR(40),
	ProviderName NVARCHAR(60),
	Address NVARCHAR(100),
	PhoneNumber VARCHAR(20),
	PRIMARY KEY(ProviderId, CategoryId, ProductId),
	CONSTRAINT CHECK_Provider_PhoneNumber CHECK (ISNUMERIC(PhoneNumber) = 1),
	CONSTRAINT FK_Provider_Cate FOREIGN KEY(CategoryId) 
	REFERENCES  DIENMAYSTOREDATABASE.dbo.Category(CategoryId),
	CONSTRAINT FK_Provider_Prduct FOREIGN KEY(ProductId ) 
	REFERENCES  DIENMAYSTOREDATABASE.dbo.Product(ProductId)
	
)
GO

-- CREATE TABLE Store
CREATE TABLE DIENMAYSTOREDATABASE.dbo.Store(
	 StoreId VARCHAR(40),
	 ProductId VARCHAR(40),
	 StoreName NVARCHAR(MAX) NOT NULL,
	 StoreAddress NVARCHAR(MAX) NOT NULL,
	 OpenDate DATETIME,
	 [StoreLength(m)] FLOAT NOT NULL,
	 [StoreWidth(m)] FLOAT NOT NULL,
	 CurrentCost FLOAT NOT NULL,
	 Status NVARCHAR(40)
	 PRIMARY KEY(StoreId, ProductId),
	 CONSTRAINT FK_Store_ProductId FOREIGN KEY(ProductId)
	 REFERENCES Product(ProductId),
	 CONSTRAINT Check_Store_Status CHECK(Status IN ('active', 'no active'))
);
-- CREATE TABLE Payment

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Payment(
	PaymentId VARCHAR(40) PRIMARY KEY,
	PaymentName NVARCHAR(100) NOT NULL,
	PaymentDescription NVARCHAR(MAX),
	PaymentDisCount NVARCHAR(100)
);

-- CREATE TABLE Cart

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Cart(
	CartId VARCHAR(40),
	CustomerId VARCHAR(20),
	ProductId VARCHAR(40),
	DisCount NVARCHAR(100),
	NumberProduct INT,
	PRIMARY KEY(CartId,CustomerId,ProductId ),
    CONSTRAINT FK_Cart_ProductId FOREIGN KEY(ProductId)
	REFERENCES Product(ProductId),
	CONSTRAINT FK_Cart_CustomerId FOREIGN KEY(CustomerId)
	REFERENCES Customer(CustomerId)
);

-- CREATE TABLE Order

CREATE TABLE DIENMAYSTOREDATABASE.dbo.[Order] (
	OrderId VARCHAR(40),
	CustomerId VARCHAR(20),
	ProductId VARCHAR(40),
	OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
	DeliveryDate DATETIME NOT NULL,
	NumberProduct INT,
	CartId VARCHAR(20),
	PaymentId VARCHAR(40),
	PRIMARY KEY (OrderId, CustomerId, ProductId),
	CONSTRAINT FK_Order_ProductId FOREIGN KEY (ProductId)
		REFERENCES DIENMAYSTOREDATABASE.dbo.Product (ProductId),
	CONSTRAINT FK_Order_CustomerId FOREIGN KEY (CustomerId)
		REFERENCES DIENMAYSTOREDATABASE.dbo.Customer (CustomerId),
	CONSTRAINT FK_Order_Paymentid FOREIGN KEY(PaymentId)
		REFERENCES DIENMAYSTOREDATABASE.dbo.Payment(PaymentId)
);

-- CREATE TABLE Rate

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Rate(
	RateId INT PRIMARY KEY IDENTITY(100,1),
	CustomerId VARCHAR(20),
	ProductId VARCHAR(40),
	Star INT NOT NULL,
	Comment NVARCHAR(MAX),
    CONSTRAINT FK_Rate_ProductId FOREIGN KEY(ProductId)
	REFERENCES Product(ProductId),
	CONSTRAINT FK_Rate_CustomerId FOREIGN KEY(CustomerId)
	REFERENCES Customer(CustomerId)
);

-- CREATE TABLE Position

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Position(
	PositionId VARCHAR(40) PRIMARY KEY,
	PositionName NVARCHAR(60) NOT NULL,
	DepartmentName NVARCHAR(60) NOT NULL,
	PositionInfo VARCHAR(MAX)
);

-- CREATE TABLE Employee

CREATE TABLE DIENMAYSTOREDATABASE.dbo.Employee(
	EmployeeId VARCHAR(20) PRIMARY KEY,
	EmployeeName NVARCHAR(40) NOT NULL,
	Account NVARCHAR(60) NOT NULL UNIQUE,
	PassWord NVARCHAR(40) NOT NULL,
	Email NVARCHAR(Max),
	BirthDate DATE,
	PhoneNumber CHAR(20) NOT NULL UNIQUE,
	Address NVARCHAR(150),
	Gender VARCHAR(10) NOT NULL,
    PositionId VARCHAR(40) NOT NULL,
	StartWorkingDate DATE NOT NULL,
	StartCurentPositionDate DATE NOT NULL
	--Thiết lập Constraint
	CONSTRAINT FK_Employee_PositionId FOREIGN KEY(PositionId)
	REFERENCES  Position(PositionId),
	CONSTRAINT CHECK_Employee_PhoneNumber CHECK (ISNUMERIC(PhoneNumber) = 1),
	CONSTRAINT CHECK_Employee_Password CHECK (
    PassWord LIKE '%[0-9]%' AND
    PassWord LIKE '%[a-z]%' AND
    PassWord LIKE '%[^a-zA-Z0-9]%'
),
	CONSTRAINT CHECK_Employee__Email CHECK (Email LIKE '%@gmail.com'),
	CONSTRAINT CHECK_Employee__Gender CHECK (Gender IN ('F', 'M', 'O'))
);

GO
-- CREATE FUNCTION CHECK CONDITION FOR Product Status
CREATE FUNCTION dbo.CheckImportBillStatus (@totalcost FLOAT, @amountpaid FLOAT)
RETURNS VARCHAR(40)
AS
BEGIN
	DECLARE @value FLOAT
	SET @value = @totalcost - @amountpaid
    DECLARE @result VARCHAR(40)

    SET @result = CASE WHEN @value <= 0 THEN 'Complete Payment' ELSE 'Has Not Been Completed Payment '
                  END

    RETURN @result
END

GO
-- CREATE TABLE Import Bill

CREATE TABLE DIENMAYSTOREDATABASE.dbo.ImportBill(
	BillId INT PRIMARY KEY IDENTITY (100, 3),
	ProviderId VARCHAR(60) NOT NULL,
    CategoryId VARCHAR(40) NOT NULL,
	ProductId VARCHAR(40) NOT NULL,
	BillDescription NVARCHAR(MAX) NOT NULL,
	TotalCost FLOAT NOT NULL,
	AmoutPaid FLOAT NOT NULL,
	Status	NVARCHAR(30),
	CONSTRAINT PK_ImportBill FOREIGN KEY(ProviderId, CategoryId, ProductId)
	REFERENCES Provider(ProviderId, CategoryId, ProductId)
);
GO

-- CREATE TRIGGER TO UPDATE AUTOMATICALLY ProductStatus WHEN  number of present product < lowlimit
CREATE TRIGGER trg_UpdateImportBillStatus
ON DIENMAYSTOREDATABASE.dbo.ImportBill
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE b
    SET b.Status = dbo.CheckImportBillStatus(b.TotalCost,b.AmountPaid)
END

GO

-- CREATE TRIGGER TO UPDATE AUTOMATICALLY TOTALSPEND ATTRIBUTE OF CUSTOMER TABLE WHEN CUSTOMER CONDUCT TRANSACTION 

CREATE TRIGGER trg_UpdateCustomerTotalSpend
ON DIENMAYSTOREDATABASE.dbo.[Order]
AFTER INSERT, UPDATE
AS
	BEGIN
		WITH cte_orderAmout AS (
		SELECT
			o.CustomerId AS CustomerId,
			o.NumberProduct AS ProductNumber,
			p.Price AS Price,
			o.NumberProduct * p.Price AS Amount
		FROM
			[Order] o 
			INNER JOIN
			Product p 
			ON o.ProductId = p.ProductId 
	),

		cte_CustomertotalAmout as (

		SELECT
			 CustomerId,
			 Sum(Amount) AS TotalAmount
		FROM
			cte_orderAmount
		GROUP BY 
			1
		)
			UPDATE c 
			SET c.TotalSpend = a.TotalAmount
			FROM DIENMAYSTOREDATABASE.dbo.Customer AS c
			INNER JOIN cte_CustomertotalAmout AS a
			ON a.CustomerId = c.CustomerId
			INNER JOIN inserted AS i 
			ON c.CustomerId = i.CustomerId	
	END
GO

-- CREATE A TRIGGER TO MONITOR ADD, UPDATE, AND DELETE ACTIVITIES OF THE CUSTOMER TABLE
 
CREATE TABLE CustomerAudits( 
		CustomerAuditId INT IDENTITY PRIMARY KEY, 
		CustomerId VARCHAR(20),
		CustomerName NVARCHAR(40) NOT NULL,
		Account NVARCHAR(60) NOT NULL,
		AccoutDescription NVARCHAR(MAX),
		PassWord NVARCHAR(40) NOT NULL,
		Email NVARCHAR(Max),
		BirthDate DATE,
		TotalSpend FLOAT DEFAULT 0,
		TotalSpendRank VARCHAR(20),
		PhoneNumber1 CHAR(20) NOT NULL,
		PhoneNumber2 CHAR(20),
		UpdateAt DATETIME NOT NULL, 
		Operation CHAR(3) NOT NULL, 
		CHECK(Operation = 'INS' OR Operation = 'DEL' OR Operation = 'UPD') 
	);	 
GO
	
CREATE OR ALTER TRIGGER TR_CustomerAudits_AfterIUD 
	ON dbo.Customer
	AFTER INSERT, DELETE, UPDATE 
	AS 
		BEGIN 
			SET NOCOUNT ON;
			INSERT INTO CustomerAudits( 
				CustomerId,
				CustomerName,
				Account,
				AccoutDescription,
				PassWord,
				Email,
				BirthDate,
				TotalSpend,
				TotalSpendRank, 
				PhoneNumber1,
				PhoneNumber2,
				UpdateAt, 
				Operation 
			) 
			SELECT 
				ins.CustomerId,
				ins.CustomerName,
				ins.Account,
				ins.AccoutDescription,
				ins.PassWord,
				ins.Email,
				ins.BirthDate,
				ins.TotalSpend,
				ins.TotalSpendRank, 
				ins.PhoneNumber1,
				ins.PhoneNumber2, 
				GETDATE(), 
				'INS' 
			FROM 
				INSERTED ins
			UNION ALL 

			SELECT 
				ins.CustomerId,
				ins.CustomerName,
				ins.Account,
				ins.AccoutDescription,
				ins.PassWord,
				ins.Email,
				ins.BirthDate,
				ins.TotalSpend,
				ins.TotalSpendRank, 
				ins.PhoneNumber1,
				ins.PhoneNumber2, 
				GETDATE(), 
				'UPD' 
			FROM 
				INSERTED ins
			WHERE
				ins.CustomerId IN ( -- chỉ xét các bản ghi được update
					SELECT 
						CustomerId
					FROM
						deleted
				)

			UNION ALL
			SELECT 
				del.CustomerId,
				del.CustomerName,
				del.Account,
				del.AccoutDescription,
				del.PassWord,
				del.Email,
				del.BirthDate,
				del.TotalSpend,
				del.TotalSpendRank, 
				del.PhoneNumber1,
				del.PhoneNumber2, 
				GETDATE(), 
				'DEL' 
			FROM 
				DELETED del
			WHERE
				del.CustomerId NOT IN( 
					SELECT 
						CustomerId
					FROM
						inserted
				)
		END	

GO
-- CREATE INDEX NON_CLUSTER TO OPTIMIZE QUERIES FOR SOME COLUMNS 

CREATE INDEX IX_Customers_CustomerName
ON Customer(CustomerName)
INCLUDE(TotalSpend, Account, Password, TotalSpendRank)

CREATE INDEX IX_Orders_OrderDate
ON [Order](OrderDate)
INCLUDE(DeliveryDate, NumberProduct)
