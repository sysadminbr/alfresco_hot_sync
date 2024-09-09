#!/bin/bash
# CITRA IT - EXCELENCIA EM TI
# Script para sincronizacao do alfresco
# @author: luciano@citrait.com.br
# @date: 18/12/2022
# use crontab to schedule this script execution
# homologado para alfresco versão: 6.0.2.1-ea
# este script deve ser executado no host stand by
# configure no alfresco produção um rsync daemon apontando para a pasta do alfresco.


# TODO
# make a API request to solr to execute a immediate backup of his indexes instead of rely on last backup (03:00am default)
# coyping solr4 indexes (alfresco) from last backup
a=$( ssh root@alfresco-prod ls /opt/alfresco/alf_data/solr4Backup/alfresco )
b=$( echo $a | python3 -c "a = input(); print(a.split(' ')[-1])" )
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress \
    alfresco-prod::alfresco/alf_data/solr4Backup/alfresco/${b}/ /opt/alfresco/alf_data/solr4/index/workspace/SpacesStore/index


# copiando os indices do solr4 - archive
a=$( ssh root@alfresco-prod ls /opt/alfresco/alf_data/solr4Backup/archive )
b=$( echo $a | python3 -c "a = input(); print(a.split(' ')[-1])" )
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress \
    alfresco-prod::alfresco/alf_data/solr4Backup/archive/${b}/ /opt/alfresco/alf_data/solr4/index/archive/SpacesStore/index



# Exportando o banco e importando localmente
#. iniciando o postgresql localmente
/opt/alfresco/postgresql/scripts/ctl.sh start

#x. excluindo o banco de dados local
PGPASSWORD=password /opt/alfresco/postgresql/bin/psql -U postgres -c "drop database alfresco"

#x. criando um banco alfresco vazio apenas como placeholder
PGPASSWORD=password /opt/alfresco/postgresql/bin/psql -U postgres -c "create database alfresco"

#x. trazendo dump do banco do servidor de producao
rm -rf /tmp/alfresco.db.dump.fc
ssh root@alfresco-prod PGPASSWORD=password /opt/alfresco/postgresql/bin/pg_dump -U postgres -Fc alfresco > /tmp/alfresco.db.dump.fc

#x. importando o dump localmente
PGPASSWORD=password /opt/alfresco/postgresql/bin/pg_restore -U postgres -d alfresco /tmp/alfresco.db.dump.fc

#x. parando o postgresql localmente
/opt/alfresco/postgresql/scripts/ctl.sh stop

## Sincronizando a pasta contentstore
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress alfresco-prod::alfresco/alf_data/contentstore/ /opt/alfresco/alf_data/contentstore

## Sincronizando a pasta amps
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress alfresco-prod::alfresco/amps/ /opt/alfresco/amps

## Sincronizando a pasta amps_share
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress alfresco-prod::alfresco/amps_share/ /opt/alfresco/amps_share

## Sincronizando a pasta tomcat
rsync  --recursive --owner --delete --perms --group --times --links --verbose --stats --progress alfresco-prod::alfresco/tomcat/ /opt/alfresco/tomcat
