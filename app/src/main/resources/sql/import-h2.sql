-- password in plaintext: "password"
INSERT INTO USER (user_id, password, email, username, name, last_name, active)
VALUES (1, '$2a$06$OAPObzhRdRXBCbk7Hj/ot.jY3zPwR8n7/mfLtKIgTzdJa4.6TwsIm', 'admin@mallamshehu.com', 'admin', 'Mallam', 'Shehu', 1);
INSERT INTO USER (user_id, password, email, username, name, last_name, active)
VALUES (2, '$2a$06$OAPObzhRdRXBCbk7Hj/ot.jY3zPwR8n7/mfLtKIgTzdJa4.6TwsIm', 'john@example.com', 'johndoe', 'John', 'Doe', 1);

INSERT INTO ROLE (role_id, role) VALUES (1, 'ROLE_ADMIN');
INSERT INTO ROLE (role_id, role) VALUES (2, 'ROLE_USER');

INSERT INTO USER_ROLE (user_id, role_id) VALUES (1, 1);
INSERT INTO USER_ROLE (user_id, role_id) VALUES (1, 2);
INSERT INTO USER_ROLE (user_id, role_id) VALUES (2, 2);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Beef Suya', 'Classic Northern Nigeria grilled beef skewers coated in yaji spice blend — served with sliced onions and tomatoes', 50, 2500.00);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Chicken Suya', 'Tender boneless chicken thigh skewers marinated overnight in our signature yaji blend and grilled over open flame', 40, 2000.00);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Ram Suya', 'Premium ram meat skewers — smoky, spiced and grilled to perfection, available on weekends', 20, 3500.00);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Kilishi', 'Sun-dried spiced beef strips — a Northern Nigerian delicacy, thinly sliced and packed with bold flavour', 30, 3000.00);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Mixed Offal Suya', 'A rich mix of liver, kidney and heart skewers seasoned with yaji, grilled fresh to order', 25, 1800.00);
