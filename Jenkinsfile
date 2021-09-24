pipeline {
  tools{
    terraform 'terraform'
  }
  agent any
  stages{
    stage('Provisioning VM on Proxmox with Terraform'){
      steps{
         sh 'echo Provisioning VM on Proxmox with Terraform'
        withCredentials([usernamePassword(credentialsId: 'Proxmox', passwordVariable: 'xbXif4P82Q88iA==', usernameVariable: 'th_digirolamo')]) {
          sh label: '', script: 'cd Provisioning; terraform init '
          sh label: '', script: 'cd Provisioning; export PM_USER=${USER}; export PM_PASS=${PASSWORD}; terraform apply  --auto-approve'
        
        }
      }
    }
    

    stage('Resource Configuration'){
      steps{
        sh 'echo Resource Configuration'
        
        withCredentials([usernamePassword(credentialsId: 'digirolamo2', passwordVariable: '123456789', usernameVariable: 'digirolamo2'), usernamePassword(credentialsId: 'digirolamo2', passwordVariable: '123456789', usernameVariable: ''), usernamePassword(credentialsId: 'digirolamo', passwordVariable: '123456789', usernameVariable: 'digirolamo'), usernamePassword(credentialsId: 'digirolamo', passwordVariable: '123456789', usernameVariable: '')]){
          ansiblePlaybook become: true, credentialsId: 'node', disableHostKeyChecking: true, installation: 'ansible', inventory: 'hosts', playbook: 'Resource Configuration/set_up_cluster.yml'
        
        }
      }
    }
    stage('Static Assessment Provisioned Environment'){
      steps{
        sh 'echo Static Assessment Provisioned Environment'
        
        withCredentials([usernamePassword(credentialsId: 'digirolamo2', passwordVariable: '123456789', usernameVariable: 'digirolamo2'), usernamePassword(credentialsId: 'digirolamo2', passwordVariable: '123456789', usernameVariable: ''), usernamePassword(credentialsId: 'digirolamo', passwordVariable: '123456789', usernameVariable: 'digirolamo'), usernamePassword(credentialsId: 'digirolamo', passwordVariable: '123456789', usernameVariable: '')]){
          ansiblePlaybook become: true, credentialsId: 'node', disableHostKeyChecking: true, installation: 'ansible', inventory: 'hosts', playbook: 'Static Security Assessment/assessment_playbook.yml'
       
       }
      }
    }
    stage('Deploy'){
      steps{
         sh 'echo Deploy'
        
        script{
         load "version.txt"
         //Change to accept post build parameter from microservice related Pipeline
          if(params.WP){
            env.WP=params.WP
          }
          if(params.WP_DB){
            env.WP_DB=params.WP_DB
          }
         kubernetesDeploy configs: 'Deploy/Kubernetes/deployments.yaml', kubeConfig: [path: ''], kubeconfigId: 'kubconf', secretName: '', ssh: [sshCredentialsId: '*', sshServer: ''], textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']        
        } 
      }    
    }
    stage('DAST'){//1
      steps{//2
       // sh 'echo DAST'
       
      withCredentials([usernamePassword(credentialsId: 'digirolamo', passwordVariable: '123456789', usernameVariable: 'digirolamo'), usernamePassword(credentialsId: 'root', passwordVariable: '123456789', usernameVariable: 'root') ,string(credentialsId:'192.168.6.131', variable:'192.168.6.131'),, string(credentialsId:'192.168.6.78', variable:'192.168.6.78')]){//3
          script{//4
            def remote = [:]
            remote.name = "${MASTER_USER}"
            remote.host = "${MASTER_IP}"
            remote.user = "${MASTER_USER}"
            remote.password = "${MASTER_PASS}"
            remote.allowAnyHosts = true
            
            def kali = [:]
            kali.name = "${KALI_USER}"
            kali.host = "${KALI_IP}"
            kali.user = "${KALI_USER}"
            kali.password = "${KALI_PASS}"
            kali.allowAnyHosts = true
            
            sh 'echo "DAST in ZAP Container"'
            kubernetesDeploy configs: 'DAST/zap.yaml', kubeConfig: [path: ''], kubeconfigId: 'provafile', secretName: '', ssh: [sshCredentialsId: '*', sshServer: ''], textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']        
            
            sh 'echo "DAST in Kali-Linux"'
            sshPut remote: kali, from: 'DAST/kali_zap.sh', into: '.'
            sshCommand remote: kali, command: "chmod +x kali_zap.sh && ./kali_zap.sh http://192.168.6.78:8080 /tmp/kali_zap_Report.html"
            //delete oscap pod
            kubernetesDeploy configs: 'DAST/zap.yaml', kubeConfig: [path: ''], deleteResource: 'true', kubeconfigId: 'provafile', secretName: '', ssh: [sshCredentialsId: '*', sshServer: ''], textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']        
            //get report
            sshGet remote: kali, from: "/tmp/kali_zap_Report.html", into: "${WORKSPACE}/Results/${JOB_NAME}_kali_zap_report.html", override: true
            sshGet remote: remote, from: "/tmp/zap/${JOB_NAME}.html", into: "${WORKSPACE}/Results/${JOB_NAME}.html", override: true
            
            sh 'echo WPScan in Kali-Linux'
            sshPut remote: kali, from: 'DAST/kali_wpscan.sh', into: '.'
            sshCommand remote: kali, command: "chmod +x kali_zap.sh && ./kali_zap.sh {{INSERIRE ENDPOINT PER ZAP}} /tmp/kali_wpscan_Report.html"
            
            withCredentials([usernamePassword(credentialsId: 'digirolamoluca', passwordVariable: 'gittabbodege9', usernameVariable: 'digirolamoluca')]) {//5
              sh 'git remote set-url origin "https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/provaorga/${JOB_NAME}.git"'
              sh 'git add Results/*'
              sh 'git commit -m "Add report File"'
              sh 'git push origin HEAD:main'
            }//5
          }//4
        }//3
      }//2
    }//1
  }
}
