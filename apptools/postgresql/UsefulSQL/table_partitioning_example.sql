CREATE TABLE log (
  log_id SERIAL PRIMARY KEY,
  log_information JSONB,
  log_type CHAR(1) 
);

CREATE OR REPLACE FUNCTION log_insert() RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.log_type = 'u' ) THEN
        INSERT INTO log_u VALUES (NEW.*);
    ELSIF ( NEW.log_type = 'i' ) THEN
        INSERT INTO log_i VALUES (NEW.*);
     ELSIF ( NEW.log_type = 'd' ) THEN
        INSERT INTO log_d VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'Unknown log type';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_insert
    BEFORE INSERT ON log
    FOR EACH ROW EXECUTE PROCEDURE log_insert();



CREATE TABLE log_u ( CHECK ( log_type = 'u') ) INHERITS (log);
CREATE TABLE log_i ( CHECK ( log_type = 'i') ) INHERITS (log);
CREATE TABLE log_d ( CHECK ( log_type = 'd') ) INHERITS (log);

INSERT INTO log (log_information, log_type) VALUES ('{"query": "SELECT 1", "user":"x" }', 'i');

INSERT INTO  log (log_information, log_type) VALUES ('{"query": "UPDATE ...", "user":"x" }', 'u');

INSERT INTO  log (log_information, log_type) VALUES ('{"query": "DELETE ...", "user":"x" }', 'd');
VACUUM ANALYSE LOG;


EXPLAIN SELECT * FROM log WHERE log_type='i';
