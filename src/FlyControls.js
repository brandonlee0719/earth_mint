import {
	EventDispatcher,
	Quaternion,
	Vector3
} from 'three';

const _changeEvent = { type: 'change' };

class FlyControls extends EventDispatcher {

	constructor(object, mesh, domElement) {

		super();

		if (domElement === undefined) {

			console.warn('THREE.FlyControls: The second parameter "domElement" is now mandatory.');
			domElement = document;

		}

		this.object = object;
		this.mesh = mesh;
		this.domElement = domElement;

		// API

		this.movementSpeed = 1.0;
		this.rollSpeed = 0.005;

		this.dragToLook = false;
		this.autoForward = false;
		this.isDrag = false;

		// disable default target object behavior

		// internals

		const scope = this;

		const EPS = 0.000001;

		const lastQuaternion = new Quaternion();
		const lastPosition = new Vector3();

		this.tmpQuaternion = new Quaternion();

		this.mouseStatus = 0;

		const _initMoveState = { up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0 };
		this.moveState = { ..._initMoveState };
		this.point = { mx: null, my: null }
		this.moveVector = new Vector3(0, 0, 0);
		this.rotationVector = new Vector3(0, 0, 0);

		this.mousedown = function (event) {
			this.isDrag = true;

			this.point.mx = event.pageX;
			this.point.my = event.pageY;

		};

		this.mousemove = function (event) {
			if (this.isDrag) {
				const container = this.getContainerDimensions();
				const halfWidth = container.size[0] / 2;
				const halfHeight = container.size[1] / 2;

				const _mx = event.pageX;
				const _my = event.pageY;

				const _yawLeft = - (_mx - this.point.mx) / halfWidth;
				const _pitchDown = (_my - this.point.my) / halfHeight;

				const _rotationVectorX = _pitchDown;
				const _rotationVectorY = -_yawLeft;

				scope.mesh.rotation.x = this.rotationVector.x + _rotationVectorX;
				scope.mesh.rotation.y = this.rotationVector.y + _rotationVectorY;

			}

		};

		this.mouseup = function (event) {
			this.isDrag = false;

			const container = this.getContainerDimensions();
			const halfWidth = container.size[0] / 2;
			const halfHeight = container.size[1] / 2;

			this.rotationVector.x = scope.mesh.rotation.x;
			this.rotationVector.y = scope.mesh.rotation.y;

			this.point.mx = event.pageX;
			this.point.my = event.pageY;
		};

		this.update = function (delta) {

			const moveMult = delta * scope.movementSpeed;
			const rotMult = delta * scope.rollSpeed;

			scope.object.translateX(scope.moveVector.x * moveMult);
			scope.object.translateY(scope.moveVector.y * moveMult);
			scope.object.translateZ(scope.moveVector.z * moveMult);

			scope.tmpQuaternion.set(scope.rotationVector.x * rotMult, scope.rotationVector.y * rotMult, scope.rotationVector.z * rotMult, 1).normalize();
			scope.object.quaternion.multiply(scope.tmpQuaternion);

			if (
				lastPosition.distanceToSquared(scope.object.position) > EPS ||
				8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > EPS
			) {

				scope.dispatchEvent(_changeEvent);
				lastQuaternion.copy(scope.object.quaternion);
				lastPosition.copy(scope.object.position);

			}
		};

		this.updateMovementVector = function () {

			const forward = (this.moveState.forward || (this.autoForward && !this.moveState.back)) ? 1 : 0;

			this.moveVector.x = (- this.moveState.left + this.moveState.right);
			this.moveVector.y = (- this.moveState.down + this.moveState.up);
			this.moveVector.z = (- forward + this.moveState.back);

			//console.log( 'move:', [ this.moveVector.x, this.moveVector.y, this.moveVector.z ] );

		};

		this.updateRotationVector = function (f) {
		};

		this.getContainerDimensions = function () {

			if (this.domElement != document) {

				return {
					size: [this.domElement.offsetWidth, this.domElement.offsetHeight],
					offset: [this.domElement.offsetLeft, this.domElement.offsetTop]
				};

			} else {

				return {
					size: [window.innerWidth, window.innerHeight],
					offset: [0, 0]
				};

			}

		};

		this.dispose = function () {

			this.domElement.removeEventListener('contextmenu', contextmenu);
			this.domElement.removeEventListener('mousemove', _mousemove);
			this.domElement.removeEventListener('mousedown', _mousedown);
			this.domElement.removeEventListener('mouseup', _mouseup);

		};

		const _mousemove = this.mousemove.bind(this);
		const _mousedown = this.mousedown.bind(this);
		const _mouseup = this.mouseup.bind(this);

		this.domElement.addEventListener('contextmenu', contextmenu);

		this.domElement.addEventListener('mousemove', _mousemove);
		this.domElement.addEventListener('mousedown', _mousedown);
		this.domElement.addEventListener('mouseup', _mouseup);

		this.updateMovementVector();
		this.updateRotationVector();

	}

}

function contextmenu(event) {

	event.preventDefault();

}

export { FlyControls };
