-- password in plaintext: "password"
INSERT INTO USER (user_id, password, email, username, name, last_name, active)
VALUES (1, '$2a$06$OAPObzhRdRXBCbk7Hj/ot.jY3zPwR8n7/mfLtKIgTzdJa4.6TwsIm', 'admin@quickbite.com', 'admin', 'Admin', 'User', 1);
INSERT INTO USER (user_id, password, email, username, name, last_name, active)
VALUES (2, '$2a$06$OAPObzhRdRXBCbk7Hj/ot.jY3zPwR8n7/mfLtKIgTzdJa4.6TwsIm', 'john@example.com', 'johndoe', 'John', 'Doe', 1);

INSERT INTO ROLE (role_id, role) VALUES (1, 'ROLE_ADMIN');
INSERT INTO ROLE (role_id, role) VALUES (2, 'ROLE_USER');

INSERT INTO USER_ROLE (user_id, role_id) VALUES (1, 1);
INSERT INTO USER_ROLE (user_id, role_id) VALUES (1, 2);
INSERT INTO USER_ROLE (user_id, role_id) VALUES (2, 2);

INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Margherita Pizza', 'Classic tomato base, fresh mozzarella and basil', 20, 12.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('BBQ Chicken Burger', 'Grilled chicken fillet, BBQ sauce, coleslaw and pickles', 15, 10.49);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Pasta Carbonara', 'Creamy egg sauce, crispy pancetta, parmesan and black pepper', 12, 13.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Caesar Salad', 'Romaine lettuce, croutons, parmesan and Caesar dressing', 25, 8.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('BBQ Ribs Platter', 'Slow-cooked pork ribs with smoky BBQ glaze and fries', 8, 22.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Fish and Chips', 'Beer-battered cod fillet with thick-cut chips and tartare sauce', 18, 14.49);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Chocolate Lava Cake', 'Warm dark chocolate cake with a molten centre and vanilla ice cream', 30, 7.49);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Mango Smoothie', 'Fresh mango, yoghurt and a hint of honey, served chilled', 40, 5.49);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Garlic Bread', 'Toasted ciabatta with roasted garlic butter and fresh herbs', 50, 4.49);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Tiramisu', 'Italian classic with espresso-soaked ladyfingers and mascarpone cream', 20, 6.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Chicken Tacos', 'Spiced grilled chicken, avocado, salsa and sour cream in soft tortillas', 22, 11.99);
INSERT INTO PRODUCT (name, description, quantity, price)
VALUES ('Tom Yum Soup', 'Spicy Thai prawn soup with lemongrass, kaffir lime and mushrooms', 14, 9.99);
