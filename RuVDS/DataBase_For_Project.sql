/*Таблицы*/
CREATE TABLE [Virtual_servers] (
    id int IDENTITY PRIMARY KEY,
    [create_datetime] datetime NOT NULL,
    [remove_datetime] datetime NULL,
    [time_active] time NULL,
    [hashcode] uniqueidentifier NOT NULL,
)
GO

CREATE TABLE [Servers_UsageTime] (
    id int IDENTITY PRIMARY KEY,
    [last_creation_datetime] datetime2 NULL,
    [total_usage_time] time NULL
)

CREATE TABLE [Errors_transactions] (
    id int IDENTITY PRIMARY KEY,
    [error_number] int NULL,
    [status_transaction] INT NULL,
    [message_error] varchar(1000) NULL, 
    [source_error] varchar(100) NULL,
    [datetime_error] datetime2 NULL
)
GO

/*Хранимые процедуры*/

--Процедуры вставки ошибок в таблицу логирования
CREATE PROCEDURE INSERT_ERROR (@error_number INT, 
                               @status_transaction INT, 
                               @message_error VARCHAR(1000),
                               @source_error VARCHAR(100),
                               @datetime_error DATETIME2)
    AS
    BEGIN TRANSACTION
        BEGIN TRY
            INSERT INTO Errors_transactions ([error_number], [status_transaction], [message_error], [source_error], [datetime_error])
            VALUES (@error_number, @status_transaction, @message_error, @source_error, @datetime_error);
            COMMIT;
        END TRY
        BEGIN CATCH 
            ROLLBACK;
        END CATCH
    GO

--Процедура добавления сервера в таблицу
CREATE PROCEDURE [add_server] 
    AS
    BEGIN TRANSACTION 
    BEGIN TRY
        SET XACT_ABORT, NOCOUNT ON;
        DECLARE @uniqueident varchar(200) = NEWID();

        INSERT INTO [Virtual_servers] VALUES (SYSDATETIME(), null, '00:00:00', @uniqueident);

        COMMIT;
    END TRY

    BEGIN CATCH
            DECLARE @error_number INT = Error_Number(), @status_transaction INT = XAct_state(), 
            @message_error VARCHAR(1000) = Error_Message(), @source_error VARCHAR(100) = Error_Procedure(), 
            @datetime_error DATETIME2 = SYSDATETIME();
        ROLLBACK;
        BEGIN TRANSACTION 
                SET XACT_ABORT, NOCOUNT ON
                    BEGIN TRY 
                        EXECUTE INSERT_ERROR @error_number, @status_transaction, @message_error, @source_error, @datetime_error;
                        SELECT 'Данные не были добавлены из-за возникшего исключения, данные об ошибке залогированы';
                        COMMIT;
                    END TRY
                    BEGIN CATCH
                        ROLLBACK;
                    END CATCH       
    END CATCH
    GO

--Процедура удаления выбранных серверов
CREATE PROCEDURE [delete_server] (@array_id xml)
    AS
    BEGIN TRANSACTION
    BEGIN TRY

    UPDATE [Virtual_servers]
        SET [remove_datetime]= SYSDATETIME(), [time_active] = CURRENT_TIMESTAMP - [create_datetime]
        WHERE id IN (SELECT tt.value('@id', 'int')
                        FROM @array_id.nodes('/servers/server') T(tt));

        UPDATE [Servers_UsageTime] 
        SET total_usage_time = ((SELECT DATEADD(ms, MAX(DATEDIFF(ms, '00:00:00.000', total_usage_time)), '00:00:00.000') FROM [Servers_UsageTime]) + 
        (SELECT DATEADD(ms, MAX(DATEDIFF(ms, '00:00:00.000', time_active)), '00:00:00.000') 
        FROM [Virtual_servers] WHERE id IN (SELECT tt.value('@id', 'int')
                                            FROM @array_id.nodes('/servers/server') T(tt)))
        );                  
        COMMIT;
    END TRY

    BEGIN CATCH
        DECLARE @error_number INT = Error_Number(), @status_transaction INT = XAct_state(), 
        @message_error VARCHAR(1000) = Error_Message(), @source_error VARCHAR(100) = Error_Procedure(), 
        @datetime_error DATETIME2 = SYSDATETIME();
    ROLLBACK;
    BEGIN TRANSACTION 
            SET XACT_ABORT, NOCOUNT ON
                BEGIN TRY 
                    EXECUTE INSERT_ERROR @error_number, @status_transaction, @message_error, @source_error, @datetime_error;
                    SELECT 'Данные не был удалены из-за возникшего исключения, данные об ошибке залогированы';
                    COMMIT;
                END TRY
                BEGIN CATCH
                    ROLLBACK;
                END CATCH       
    END CATCH
    GO

--Процедура получения серверов из таблицы
CREATE PROCEDURE [get_info_about_servers] (@TotalUsageTime datetime2 OUTPUT)
    AS
    BEGIN TRANSACTION 
    BEGIN TRY 
        SET XACT_ABORT, NOCOUNT ON;
         
                IF NOT EXISTS ((SELECT remove_datetime FROM Virtual_servers WHERE remove_datetime IS NULL)) 
                AND NOT EXISTS (SELECT ID FROM (SELECT ID, CREATE_DATETIME, REMOVE_DATETIME, LEAD(CREATE_DATETIME, 1) OVER (ORDER BY CREATE_DATETIME) AS NEXT, TIME_ACTIVE FROM Virtual_servers) AS LEAD WHERE NEXT > REMOVE_DATETIME)    
                BEGIN
                SET @TotalUsageTime = ((SELECT MAX(remove_datetime) FROM Virtual_servers) - (SELECT MIN(create_datetime) FROM Virtual_servers));
                END;

                ELSE IF NOT EXISTS ((SELECT remove_datetime FROM Virtual_servers WHERE remove_datetime IS NULL))
                AND EXISTS (SELECT ID FROM (SELECT ID, CREATE_DATETIME, REMOVE_DATETIME, LEAD(CREATE_DATETIME, 1) OVER (ORDER BY CREATE_DATETIME) AS NEXT, TIME_ACTIVE FROM Virtual_servers) AS LEAD WHERE NEXT > REMOVE_DATETIME)
                    BEGIN
                        SET @TotalUsageTime = (SELECT MAX(remove_datetime) - MIN(create_datetime) FROM Virtual_servers) -
                        (SELECT DATEADD(ms, SUM(DATEDIFF(ms, '00:00:00.000', ONREM)), '00:00:00.000') FROM (SELECT NEXT - remove_datetime AS ONREM FROM (SELECT ID, CREATE_DATETIME, REMOVE_DATETIME, LEAD(CREATE_DATETIME, 1) OVER (ORDER BY CREATE_DATETIME) AS NEXT, TIME_ACTIVE FROM Virtual_servers) AS LEAD WHERE NEXT > REMOVE_DATETIME) AS SUM);
                        UPDATE Servers_UsageTime
                        SET total_usage_time = @TotalUsageTime;
                    END;

                SELECT *
                FROM Virtual_servers;
        COMMIT;
    END TRY
    
    BEGIN CATCH
            DECLARE @error_number INT = Error_Number(), @status_transaction INT = XAct_state(), 
            @message_error VARCHAR(1000) = Error_Message(), @source_error VARCHAR(100) = Error_Procedure(), 
            @datetime_error DATETIME2 = SYSDATETIME();
        ROLLBACK;
        BEGIN TRANSACTION 
                SET XACT_ABORT, NOCOUNT ON
                    BEGIN TRY 
                        EXECUTE INSERT_ERROR @error_number, @status_transaction, @message_error, @source_error, @datetime_error;
                        SELECT 'Данные не был удалены из-за возникшего исключения, данные об ошибке залогированы';
                        COMMIT;
                    END TRY
                    BEGIN CATCH
                        ROLLBACK;
                    END CATCH       
    END CATCH
    GO

CREATE PROCEDURE [Delete_All_Servers] 
    AS
    SET NOCOUNT ON

    TRUNCATE TABLE [Virtual_servers];
    TRUNCATE TABLE [Servers_UsageTime];
    GO

