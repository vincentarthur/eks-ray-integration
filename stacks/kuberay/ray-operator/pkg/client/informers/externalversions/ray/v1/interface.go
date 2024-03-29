// Code generated by informer-gen. DO NOT EDIT.

package v1

import (
	internalinterfaces "github.com/ray-project/kuberay/ray-operator/pkg/client/informers/externalversions/internalinterfaces"
)

// Interface provides access to all the informers in this group version.
type Interface interface {
	// RayClusters returns a RayClusterInformer.
	RayClusters() RayClusterInformer
	// RayJobs returns a RayJobInformer.
	RayJobs() RayJobInformer
	// RayServices returns a RayServiceInformer.
	RayServices() RayServiceInformer
}

type version struct {
	factory          internalinterfaces.SharedInformerFactory
	namespace        string
	tweakListOptions internalinterfaces.TweakListOptionsFunc
}

// New returns a new Interface.
func New(f internalinterfaces.SharedInformerFactory, namespace string, tweakListOptions internalinterfaces.TweakListOptionsFunc) Interface {
	return &version{factory: f, namespace: namespace, tweakListOptions: tweakListOptions}
}

// RayClusters returns a RayClusterInformer.
func (v *version) RayClusters() RayClusterInformer {
	return &rayClusterInformer{factory: v.factory, namespace: v.namespace, tweakListOptions: v.tweakListOptions}
}

// RayJobs returns a RayJobInformer.
func (v *version) RayJobs() RayJobInformer {
	return &rayJobInformer{factory: v.factory, namespace: v.namespace, tweakListOptions: v.tweakListOptions}
}

// RayServices returns a RayServiceInformer.
func (v *version) RayServices() RayServiceInformer {
	return &rayServiceInformer{factory: v.factory, namespace: v.namespace, tweakListOptions: v.tweakListOptions}
}
