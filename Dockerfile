FROM frooodle/s-pdf:0.39.0

# Définit le répertoire de travail explicite
WORKDIR /usr/src/app

# Vérifie que le script existe et corrige les permissions
RUN chmod +x ./run.sh && \
    chown -R 1000:1000 /usr/src/app

# Port exposé (doit correspondre au port interne de l'application)
EXPOSE 8080

# Commande d'exécution avec chemin absolu
CMD ["/usr/src/app/run.sh"]
