# Utilise l'image officielle de Stirling PDF
FROM frooodle/s-pdf:latest

# Exposition du port utilisé par l'application
EXPOSE 8080

# Démarrage de l'application
CMD ["./run.sh"]
