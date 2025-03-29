-- Criação do Banco de Dados
CREATE DATABASE Oficina;
USE Oficina;

-- Tabela Cliente
CREATE TABLE Cliente (
    ID_Cliente INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Telefone VARCHAR(15),
    Endereco VARCHAR(200)
);

-- Tabela Veículo
CREATE TABLE Veiculo (
    ID_Veiculo INT AUTO_INCREMENT PRIMARY KEY,
    Placa VARCHAR(10) NOT NULL UNIQUE,
    Modelo VARCHAR(50),
    Marca VARCHAR(50),
    Ano INT,
    ID_Cliente INT NOT NULL,
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabela Equipe
CREATE TABLE Equipe (
    ID_Equipe INT AUTO_INCREMENT PRIMARY KEY,
    Nome_Equipe VARCHAR(100) NOT NULL
);

-- Tabela Mecânico
CREATE TABLE Mecanico (
    ID_Mecanico INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Endereco VARCHAR(200),
    Especialidade VARCHAR(100)
);

-- Tabela Equipe-Mecânico (Relacionamento Muitos para Muitos)
CREATE TABLE Equipe_Mecanico (
    ID_Equipe INT NOT NULL,
    ID_Mecanico INT NOT NULL,
    PRIMARY KEY (ID_Equipe, ID_Mecanico),
    FOREIGN KEY (ID_Equipe) REFERENCES Equipe(ID_Equipe),
    FOREIGN KEY (ID_Mecanico) REFERENCES Mecanico(ID_Mecanico)
);

-- Tabela Ordem de Serviço
CREATE TABLE Ordem_Servico (
    Numero_OS INT AUTO_INCREMENT PRIMARY KEY,
    Data_Emissao DATE NOT NULL,
    Data_Conclusao DATE,
    Valor_Total DECIMAL(10, 2),
    Status ENUM('Pendente', 'Concluido', 'Cancelado') DEFAULT 'Pendente',
    ID_Equipe INT,
    ID_Veiculo INT NOT NULL,
    ID_Cliente INT NOT NULL,
    FOREIGN KEY (ID_Equipe) REFERENCES Equipe(ID_Equipe),
    FOREIGN KEY (ID_Veiculo) REFERENCES Veiculo(ID_Veiculo),
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabela Peça
CREATE TABLE Peca (
    ID_Peca INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Preco DECIMAL(10, 2) NOT NULL
);

-- Tabela Pecas-OS (Relacionamento Entre Peças e Ordens de Serviço)
CREATE TABLE Pecas_OS (
    Numero_OS INT NOT NULL,
    ID_Peca INT NOT NULL,
    Quantidade INT DEFAULT 1,
    Subtotal DECIMAL(10, 2),
    PRIMARY KEY (Numero_OS, ID_Peca),
    FOREIGN KEY (Numero_OS) REFERENCES Ordem_Servico(Numero_OS),
    FOREIGN KEY (ID_Peca) REFERENCES Peca(ID_Peca)
);

-- Tabela Serviço
CREATE TABLE Servico (
    ID_Servico INT AUTO_INCREMENT PRIMARY KEY,
    Descricao VARCHAR(200),
    Preco_Mao_Obra DECIMAL(10, 2) NOT NULL
);

-- Tabela Serviços-OS (Relacionamento Entre Serviços e Ordens de Serviço)
CREATE TABLE Servicos_OS (
    Numero_OS INT NOT NULL,
    ID_Servico INT NOT NULL,
    Quantidade INT DEFAULT 1,
    Subtotal DECIMAL(10, 2),
    PRIMARY KEY (Numero_OS, ID_Servico),
    FOREIGN KEY (Numero_OS) REFERENCES Ordem_Servico(Numero_OS),
    FOREIGN KEY (ID_Servico) REFERENCES Servico(ID_Servico)
);
-- REFINAMENTOS FEITOS
-- índices em colunas frequentemente consultadas
CREATE INDEX idx_cliente_nome ON Cliente(Nome);
CREATE INDEX idx_veiculo_placa ON Veiculo(Placa);

-- Triggers para automatizar cálculos
DELIMITER //

CREATE TRIGGER atualizar_valor_total
AFTER INSERT ON Pecas_OS
FOR EACH ROW
BEGIN
    UPDATE Ordem_Servico
    SET Valor_Total = COALESCE(Valor_Total, 0) + NEW.Subtotal
    WHERE Numero_OS = NEW.Numero_OS;
END;
//

DELIMITER ;

INSERT INTO Cliente (Nome, Telefone, Endereco) 
VALUES ('Maria Silva', '123456789', 'Rua das Flores, 123');
INSERT INTO Veiculo (Placa, Modelo, Marca, Ano, ID_Cliente) 
VALUES ('ABC1234', 'Corolla', 'Toyota', 2020, 1);

-- verificar todos os mecânicos da equipe
SELECT e.Nome_Equipe, m.Nome AS Nome_Mecanico
FROM Equipe e
INNER JOIN Equipe_Mecanico em ON e.ID_Equipe = em.ID_Equipe
INNER JOIN Mecanico m ON em.ID_Mecanico = m.ID_Mecanico;

-- todas as ordens de serviço em aberto
SELECT Numero_OS, Data_Emissao, Valor_Total, Status
FROM Ordem_Servico
WHERE Status = 'Pendente';

-- todos os veículos de um cliente específico
SELECT Veiculo.Placa, Veiculo.Modelo, Veiculo.Marca, Veiculo.Ano
FROM Veiculo
INNER JOIN Cliente ON Veiculo.ID_Cliente = Cliente.ID_Cliente
WHERE Cliente.Nome = 'Maria Silva';

-- custo total de uma ordem de serviço, somando o subtotal das peças e serviços
SELECT os.Numero_OS,
       SUM(ps.Subtotal) AS Total_Pecas,
       SUM(ss.Subtotal) AS Total_Servicos,
       (SUM(ps.Subtotal) + SUM(ss.Subtotal)) AS Valor_Total
FROM Ordem_Servico os
LEFT JOIN Pecas_OS ps ON os.Numero_OS = ps.Numero_OS
LEFT JOIN Servicos_OS ss ON os.Numero_OS = ss.Numero_OS
WHERE os.Numero_OS = 1
GROUP BY os.Numero_OS;

-- mecânicos de uma equipe ordenados por especialidade
SELECT m.Nome AS Nome_Mecanico, m.Especialidade
FROM Mecanico m
INNER JOIN Equipe_Mecanico em ON m.ID_Mecanico = em.ID_Mecanico
WHERE em.ID_Equipe = 1
ORDER BY m.Especialidade ASC;

-- equipes que tenham mais de 3 mecânicos
SELECT e.Nome_Equipe, COUNT(em.ID_Mecanico) AS Total_Mecanicos
FROM Equipe e
INNER JOIN Equipe_Mecanico em ON e.ID_Equipe = em.ID_Equipe
GROUP BY e.Nome_Equipe
HAVING COUNT(em.ID_Mecanico) > 3;



