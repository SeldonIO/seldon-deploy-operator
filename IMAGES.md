# Publishing and Using Images

## Certified Images - Notes

You can get to certified image listings through RH access portal. Creds https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=pbdteciyqnp3rsxpcrkaxevftm&v=po7kyvksukhlrsurwmygolab3a

Here is the old operator image https://connect.redhat.com/project/4805411/view

If you go to Settings from that page then you see how to pull the image.

Passwords for uploading in https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=f4hgces2dvxqirpcsir2uiqbe4&v=65l42gglwnfjheao6fu4pmxeti

Under images there is a 'push image manually' button that takes you to credentials for pushing.

The script that was used to push it was https://github.com/SeldonIO/seldon-deploy-operator/blob/8531183514393f0040f4856ff7da4507aa2841c5/Makefile#L15

A checklist is run on the redhat side. That is shown under 'Checklist' in the UI. licenses are required in Docker images.

# List of Images

Bundle (packages the catalog listing)
Operator (runs the helm operator to manage SeldonDeploy CRD)
Deploy Server (what we normally call Deploy)
Batchjobs processor image
Batchjobs mc image
Request logger (published with core?)
Kubectl
Loadtester
Alibi detect

See manager.yaml. Any images used in helm chart have to be referenced there by RELATED_IMAGE_

The RELATED_IMAGE_ will always be replaced, irrespective of what's in the values file. This is for handling airgapped.

There's separate manifests for certified. This is because RCR images don't work on KIND since you have to log in to pull. (Verify this?)

So should have two make targets for each of the above (either here or in Deploy repo), one for RCR and one for docker or quay.

Make a table?