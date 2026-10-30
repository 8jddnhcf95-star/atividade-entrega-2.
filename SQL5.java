package com.scopino.dao;

import com.scopino.config.ConexaoBanco;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class OrdemServicoDAO {

    // Método para listar todas as Ordens de Serviço (Relatório Gerencial G01)
    public void listarOrdensServico() {
        String sql = "SELECT os.id_os, c.nome AS cliente, v.modelo, v.placa, " +
                     "m.nome AS mecanico, os.status, os.valor_total " +
                     "FROM ORDEM_SERVICO os " +
                     "JOIN VEICULO v ON os.id_veiculo = v.id_veiculo " +
                     "JOIN CLIENTE c ON v.id_cliente = c.id_cliente " +
                     "JOIN MECANICO m ON os.id_mecanico = m.id_mecanico " +
                     "ORDER BY os.id_os ASC";

        try (Connection conn = ConexaoBanco.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            System.out.println("\n-----------------------------------------------------------------------------------");
            System.out.printf("%-6s | %-20s | %-12s | %-10s | %-15s | %-12s | %-10s\n", 
                              "OS", "Cliente", "Modelo", "Placa", "Mecânico", "Status", "Valor Total");
            System.out.println-----------------------------------------------------------------------------------");

            while (rs.next()) {
                System.out.printf("%-6d | %-20s | %-12s | %-10s | %-15s | %-12s | R$ %-8.2f\n",
                        rs.getInt("id_os"),
                        rs.getString("cliente"),
                        rs.getString("modelo"),
                        rs.getString("placa"),
                        rs.getString("mecanico"),
                        rs.getString("status"),
                        rs.getDouble("valor_total"));
            }
            System.out.println("-----------------------------------------------------------------------------------\n");

        } catch (SQLException e) {
            System.err.println("Erro ao buscar Ordens de Serviço: " + e.getMessage());
        }
    }

    // Método para atualizar status de uma OS
    public boolean atualizarStatus(int idOs, String novoStatus) {
        String sql = "UPDATE ORDEM_SERVICO SET status = ? WHERE id_os = ?";

        try (Connection conn = ConexaoBanco.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, novoStatus);
            stmt.setInt(2, idOs);

            int linhasAfetadas = stmt.executeUpdate();
            return linhasAfetadas > 0;

        } catch (SQLException e) {
            System.err.println("Erro ao atualizar status da OS: " + e.getMessage());
            return false;
        }
    }
}