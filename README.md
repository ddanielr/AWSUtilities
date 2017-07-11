# AWSUtilities
Collection of scripts and utilities that make life in AWS a bit better

Utilites: 
 * aws-mfa.sh
   
   You can run this in your .bashrc by doing something like the following
   ```bash
   echo "enter MFA token"
   read token
   $(<path-to-script>aws-mfa.sh -p <profile> -t $token)
   ```

