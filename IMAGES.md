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

The table below has the make targets for the images. Each should have two, one being certified.

| Image      |  Make Targets                                        |  Status |
| ---------- |  --------------------------------------------------- | ----------- |
| Bundle     | create_bundle_image_% , ? See above link. Create?    |  TODO   |
| Operator   | docker-build, redhat-image-scan                      | lic scan fail |
| Deploy     | deploy repo, build_image_redhat & redhat-image-scan  | scan fail with no reason |
| Batch Proc | TODO                                                 | TODO |
| Batch mc   | build-minio-image, NEED TO CREATE PROJECT            | TODO |
| Req log    | In core, under components/seldon-request-logger      | republish, [image 6mo old](https://connect.redhat.com/project/3993051/images) |
| kubectl    | build-kubectl-image, redhat-kubectl-image-scan       | hasn't changed but repub |
| loadtest   | deploy repo, tools/images/loadtest-image             | hasn't changed but repub |
| alibi      | In core, under components/alibi-detect-server        | republish, [image 6mo old](https://connect.redhat.com/project/3993461/images)   |

FOR BUNDLE WE NEED A MAKE GOAL TO BUILD THE CERTIFIED ONE. HAVEN'T BUILT THAT YET.
NOT JUST RETAGGING LIKE THE OTHERS. FOR THAT CERTIFIED IS DIFFERENT.
PROJECT IS https://connect.redhat.com/project/5892521/images/upload-image

FOR OPERATOR IMAGE FAILING LIC SCAN - DEPLOY TO K8S AND EXEC INTO THEN LIST.

DEPLOY OPERATOR SCAN FAILURE - https://connect.redhat.com/project/4805411/images
DEPLOY IMAGE SCAN FAILURE - https://connect.redhat.com/project/4805801/images
MINIO IMAGE SCAN FAILURE - https://connect.redhat.com/project/5937511/images
BATCH PROC LIC SCAN FAILURE - https://connect.redhat.com/project/5937521/images

MINIO IMAGE SCAN FAILED BUT ALL INDIVIDUAL CHECKS PASSED
SAME FOR DEPLOY. HAVE RAISED ISSUE WITH RED HAT.

CERT IMAGE NAMES IN packagemanifests-certified.sh

