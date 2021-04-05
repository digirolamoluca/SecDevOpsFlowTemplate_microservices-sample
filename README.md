SecDevOps Flow Template
=======================

SecDevOps Flow Template è uno strumento capace di eseguire un flusso di continuous integration/continuous deployment integrando attività di sicurezza. L’intervento degli sviluppatori consisterà nel fornire quelle che sono le caratteristiche proprie dell’applicazione sviluppata ed un limitato set-up dei tool utilizzati, senza dover per ogni nuovo progetto implementare la logica necessaria a seguire la metodologia proposta.
Il risultato è costituito da una serie di report riguardanti la valutazione dell'ambiente configurato, l'attivià testing dinamico eseguita e la qualità del codice prodotto. Tali report sono messi a disposizione in formato html, grazie ad essi è possibile realizzzare una valutazione complessiva sullo stato dello sviluppo prima di rilasciare l'applicazione in ambiente operativo.


# Fasi e Strumenti

![My image](https://i.ibb.co/qkGN3cC/Immagine2.png)

# Indice

- [Requisiti](#Requisiti)
- [Set-up Plugin in Jenkins](#set-up-plugin-in-jenkins)
- [Guida all'uso](#guida-alluso)
- [Licenza](#licenza)

# Requisiti
  1) Jenkins Server, con i seguenti plugin e tool installati:
      - Ansible Plugin
      - Docker Pipeline
      - GitHub
      - Kubernetes Continuous Deploy
      - SonarQube Scanner for Jenkins
      - SSH Pipeline Steps
      - Teraform Plugin
      - Docker
      - Ansible
      - Chef-InSpec
   
  2) Distro Kali-Linux

  3) Proxmox Server
      - Template da clonare con Cloud-Init abilitato
  
  4) SonarQube Server
  
  
# Set-up Plugin in Jenkins
Dalla Dashboard di Jenkins recarsi in manage Jenkins -> Global Tool Configuration per configurare i plug-in

###  SonarQube Scanner for Jenkins
![My image](https://i.ibb.co/rccGv0G/sonarqube-plugin.png)

###  Ansible Plugin
![My image](https://i.ibb.co/k110fDL/ansible-plugin.png)


###  Terraform Plugin
![My image](https://i.ibb.co/S3zQqY2/terraform-plugin.png)

### Integrazione SonarQube
Per Integrare SonarQube vi è bisogno di inserire il Server authentication token in Jenkins:
  1. Eseguire il Login nel proprio SonarQube Server e dalla barra utente Recarsi in My Account –> Security –> Generate Token
  2. Eseguire il login nel proprio Jenkins Server e recarsi in Manage Jenkins –> Configure Systems –> SonarQube Serverse:
      - Name : SonarQube
      - Server URL : indirizzo IP del sonar Server
      - Server authentication token creando delle nuove credenziali di tipo 'SecretText'
![My image](https://i.ibb.co/tLFKL41/sonarqube-token.png)

# Guida all'uso
Per poter utilizzare il template, una volta effettuato il Fork, bisogna inserire i parametri necessari al completamento di esso.  
In particoalre i file su cui bisogna agire sono:
  - Provisioning
      - resource.tf
      - provider.tf
  - hosts
  - Static Security Assessment
      - assessment_playbook.yml 
  - Microservice Files
      - Jenkinsfile
  - Jenkinsfile 
  - version.txt
  - Deploy, per caricare i manisfest di deployment

## resource.tf
E' utilizzato da Terraform per istanziare macchine virtuali in Proxmox, sulle quali verrà eseguito un cluster Kuberntes.  
I parametri da fornire sono:

_Indirizzi IP che si vogliono assegnare alle macchine virtuali_
```groovy
variable "ip_list"{
  type  =  list
  default  =  ["{IP1}","{IP2}"]
}
```
_Esempio_
```groovy
variable "ip_list"{
  type  =  list
  default  =  ["192.168.6.114","192.168.6.115"]
}
```
_Credenziali che si volgiono assegnare alle macchine virtuali_
```groovy
variable "credentials_ciuser"{
  type  =  list
  default  =  ["{USER1}","{USER2}"]
}
variable "credentials_cipassword"{
  type  =  list
  default  =  ["{PASSWORD1}","{PASSWORD2}"]
}
```
_Esempio_
```groovy
variable "credentials_ciuser"{
  type  =  list
  default  =  ["master","worker"]
}
variable "credentials_cipassword"{
  type  =  list
  default  =  ["master","worker"]
}
```
_Numero di macchine virtuali da istanziare e il nome che si vuole scegliere per esse_
```groovy
count  =  {VM_COUNT}
name   =  "{VM_NAME}${count.index}"
```
_Esempio_
```groovy
count  =  2 
name  =  "kub${count.index}"
```
_Template da clonare precedentemente creato in Proxmox_
```groovy
clone  =  "{VM_TEMPLATE_NAME}"
```
_Esempio_
```groovy
clone  =  "Deploy"
```
_Caratteristiche della macchina virtuale e pool di risorse assegante all'utente_
```groovy
memory  =  {MEMORY_IN_MB}
cores  =  "{CORE}"
pool  =  "{POOL}"
disk {
  size  =  "{SIZE_IN_MB}"
}
```
_Esempio_
```groovy
memory  =  8192
cores  =  "4"
pool  =  "Tesi_Zagaria"
disk {
  size  =  "10240M"
}
```
## provder.tf
E' utilizzato da Terraform per interfacciarsi con il provider di risorse:

_Endpoint del Server Proxmox_
```groovy
pm_api_url = "https://{IP_PROXMOX}/api2/json"
```
_Esempio_
```groovy
pm_api_url = "https://10.224.16.41:8006/api2/json"
```
## host
Costituisce l'inventario utilizzato da ansible.  
_Completare con Indirizzi IP delle macchine virtuali, precedentemente asseganti._  
_E' possibile avere più IP asseganti alle maccchine worker ma un solo IP master_
```groovy
[KubWorker]
{INSERIRE IP}

[KubMaster]
{INSERIRE IP}
```
_Esempio_
```groovy
[KubWorker]
192.168.6.114

[KubMaster]
192.168.6.115
```
## assessment_playbook.yml
Ansible playbook utilizzato per eseguire l'assessment dell'ambiante istanziato e configurato

_Inserire le policy di Chef-InSpec e OSCAP che si voglio eseguire, è possibile utilizzarne più di una duplicando i comandi del file._
```yml
  - name: Execute static assessment
    command: "{{item}}"
    with_items:
      - inspec exec {INSERIRE CHEF INSPEC PROFILE} --reporter html:/tmp/inspec_report.html --chef-license=accept
  
  - name: Transfer scap datastream
    copy: src={INSERIRE PATH POLICY OSCAP} dest=/tmp/oscap_policy.xml mode=0777
 
  - name: Execute static assessment
    command: oscap xccdf eval --profile {INSERIRE PROFILO DELLA POLICY SCELTA} --report /tmp/scap_report.html /tmp/scap_policy.xml
```
_Esempio_
```yml
  - name: Execute static assessment
    command: "{{item}}"
    with_items:
      - inspec exec https://github.com/dev-sec/linux-baseline --reporter html:/tmp/inspec_report.html --chef-license=accept
  
  - name: Transfer scap datastream
    copy: src=/home/giuseppe/Downloads/scap-security-guide-0.1.53/ssg-ubuntu1804-ds-1.2.xml dest=/tmp/scap_policy.xml mode=0777
 
  - name: Execute static assessment
    command: oscap xccdf eval --profile anssi_np_nt28_minimal --report /tmp/scap_report.html /tmp/scap_policy.xml
```

## Microservice Files/Jenkinsfile
Jenkinsfile utilizzabile per creare le pipeline in Jenkins relative ai singoli componenti che costituiscono l'applicazione

_Inserire il registry docker utilizzato per pubblicare le immagini_
_N.B. La variabile JON_NAME è già presente in Jenkins, rappresenta il nome che si sceglie per la pipeline_
```groovy
registry = "${INSERIRE RESGISTRY DOCKER-HUB}/${JOB_NAME}"
```
_Esempio_
```groovy
registry = "peppe2794/${JOB_NAME}"
```
_Inserire il profilo che si vuole utilizzar per eseguire l'assessment per componenti, nel caso se ne vogliano utiilizzare diversi aggiungere un'altra riga con un diverso nome del report_
```groovy
sh 'inspec exec ${HERE} -t docker://${IMAGE} --reporter html:/Results/inspec_report.html --chef-license=accept || true'
```
_Esempio_
```groovy
sh 'inspec exec https://github.com/dev-sec/linux-baseline -t docker://${IMAGE} --reporter html:Results/Linux_Baseline_report.html --chef-license=accept || true'
```
__Inserire il nome che si sceglierà per la pipeline in Jenkins relativa all'intera applicazione. Questa sezione è utilizzata per consentire il passaggio di parametri tra le pipeline del singolo microservizio e quella completa. Il parametro name dovrà essere diverso per ogni componente sviluppato e dovrà essere lo stesso che verrà specificato nella sezionedi relativa alla pipeline completa._
```groovy
build job: '${INSERIRE_NOME_PIPELINE_APPLICAZIONE}', parameters: [string (value: "$registry"+":"+"$DOCKER_TAG", description: 'Parametro', name: '$IMAGE')]
```
_Esempio_
```groovy
build job: 'SecDevOpsFlowTemplate_WordpressExample', parameters: [string (value: "$registry"+:"+"$DOCKER_TAG", description: 'Parametro', name: 'WP')]
```

## Jenkinsfile
Jenkinsfile utilizzabile per creare le pipeline in Jenkins dell'intera applicazione

_Inserire il construtto IF che permette di sovrascrivere le variabili d'ambiente, caricate dal file version.txt, che permettono il passaggio della verione dell'immagine del microservizio._  
_Questo permette di utilizzare la versione del microsevizio che avviato la pipeline principale_
```groovy
if(params.{IMAGE}){
  env.{IMAGE}=params.{IMAGE}
  }
```
_Esempio_
```groovy
if(params.WP){
  env.WP=params.WP
  }
if(params.WB_DB){
  env.WP_DB=params.WP_DB
  }
```
_Inserire Endpoint per la DAST da eseguire tramite Kali-Linux_
```groovy
sshCommand remote: kali, command: "chmod +x kali_zap.sh && ./kali_zap.sh {{INSERIRE ENDPOINT PER ZAP}} /tmp/kali_zap_Report.html"
```
_Esempio_
```groovy
sshCommand remote: kali, command: "chmod +x kali_zap.sh && ./kali_zap.sh http://192.168.6.76:31381 /tmp/kali_zap_Report.html"```
```
## Creare in Jenkins le seguenti credenziali, utilizzate dalla pipeline attraverso il binding dinamico:
_Credenziali Proxmox_  
```groovy
usernamePassword(credentialsId: 'Proxmox', passwordVariable: 'PASSWORD', usernameVariable: 'USER')
```
_Credenziali delle macchine virtuali (dovranno coincidere con quelle inserite in resource.tf)_  
```groovy
usernamePassword(credentialsId: 'worker', passwordVariable: 'WORKER_PASS', usernameVariable: 'WORKER_USER')  
usernamePassword(credentialsId: 'worker', passwordVariable: 'WORKER_SUDO_PASS', usernameVariable: '')  
usernamePassword(credentialsId: 'master', passwordVariable: 'MASTER_PASS', usernameVariable: 'MASTER_USER')  
usernamePassword(credentialsId: 'master', passwordVariable: 'MASTER_SUDO_PASS', usernameVariable: '')  
string(credentialsId:'MASTER_IP', variable:'MASTER_IP')
```
_Credenziali macchina Kali-Linux_  
```groovy
usernamePassword(credentialsId: 'KALI_CREDENTIALS', passwordVariable: 'KALI_PASS', usernameVariable: 'KALI_USER')  
string(credentialsId:'KALI_IP', variable:'KALI_IP')
```
_Credenziali GitHub_  
```groovy
usernamePassword(credentialsId: 'GIT', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')
```
## version.txt
File utilizzato per tenere traccia delle versioni dei componenti da utilizzare quando la pipeline principale è schedulata da un divero componente.
La versione del componente che avvia la pipeline principale sovrascrive il relativo valore tramite il blocco IF presentato precedentemente
_esempio_
```groovy
//Add here stable container image version of you appplication
//Example env.SERVICE= "IMAGE_NAME:TAG"
env.WP="peppe2794/wordpressexample:latest"
env.WP_DB="peppe2794/wordpressexample_db:latest"
```




### Link a documentazione esterna 

# Come contribuire

## Installare le dipendenze di sviluppo

## Struttura del progetto

## Community

### Code of conduct

### Responsible Disclosure

### Segnalazione bug e richieste di aiuto

# Manutenzione 

# Licenza 

## Licenza generale 

## Autori e Copyright

## Licenze software dei componenti di terze parti
