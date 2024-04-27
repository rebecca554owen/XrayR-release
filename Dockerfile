# 通过TAG参数指定镜像版本，默认使用latest
ARG TAG=latest
# 使用指定版本的xrayr镜像
FROM ghcr.io/wyx2685/xrayr:${TAG}

# 设置工作目录
WORKDIR /app

# 复制entrypoint脚本
COPY entrypoint.sh /app/entrypoint.sh

# 复制配置文件
COPY /config/ /etc/XrayR/

# 安装ca-certificates并设置entrypoint脚本可执行权限
RUN apk --update --no-cache add ca-certificates \
    && chmod +x /app/entrypoint.sh

# 设置容器启动命令
ENTRYPOINT ["/app/entrypoint.sh"]
