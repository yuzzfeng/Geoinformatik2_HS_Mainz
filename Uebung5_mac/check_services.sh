#!/bin/bash
# Uebung5 服务检查脚本

echo "🔍 检查 Docker 容器状态..."
docker compose ps

echo ""
echo "📊 检查数据库..."
docker compose exec -T db psql -U postgres -d postgres -c "SELECT name, ST_AsText(geom) FROM places;" 2>/dev/null || echo "❌ 数据库未就绪"

echo ""
echo "🌐 检查 Web 服务..."
curl -s http://localhost:5000/api/health | grep -q "ok" && echo "✅ Web 服务正常" || echo "❌ Web 服务未响应"

echo ""
echo "🗺️ 检查 GeoServer..."
curl -s http://localhost:8080/geoserver/web/ | grep -q "GeoServer" && echo "✅ GeoServer 正常" || echo "❌ GeoServer 未响应"

echo ""
echo "📝 GeoServer 初始化日志（最后 20 行）:"
docker compose logs --tail=20 geoserver-init

echo ""
echo "✨ 访问链接："
echo "   Flask App: http://localhost:5000/"
echo "   GeoServer: http://localhost:8080/geoserver (admin/geoserver)"
